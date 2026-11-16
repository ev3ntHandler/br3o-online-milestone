// weapons.js – car weapons. Owner-side hooks emit network FX (shots, tracers, sparks, booms);
// ghost-side visual replicas run damage-free on the fixed 32 Hz tick via updateVisuals().
import * as THREE from 'three';
const rand = (a, b) => a + Math.random() * (b - a);
const randInt = (a, b) => Math.floor(rand(a, b + 1));
const D2R = THREE.MathUtils.degToRad;
const GRAV = -39.24;
const PERSIST = 1e9;                       // mines stay on the field until triggered
const lowerKeys = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k.toLowerCase(), v]));
const SUPPORTED = { primary: ['MachineGun', 'DualMachineGun', 'MiniGun', 'DualMiniGun', 'Laser'], secondary: ['RocketPod', 'MineDeployer', 'GrenadeDeployer', 'GrenadeLauncher'] };
const MODELS = { MachineGun: ['MachineGun'], DualMachineGun: ['DualMachineGun'], MiniGun: ['MiniGun'], DualMiniGun: ['DualMiniGun'], Laser: ['Laser'], RocketPod: ['RocketPodLeft', 'RocketPodRight'], MineDeployer: ['MineDeployer'], GrenadeDeployer: ['GrenadeDeployer'], GrenadeLauncher: ['GrenadeLauncher'] };
const FLASHES = { MachineGun: [['MachineGunMuzzleFlash1', 'MachineGunMuzzleFlash2']], DualMachineGun: [['DualMachineGunMuzzleFlashLeft1', 'DualMachineGunMuzzleFlashLeft2'], ['DualMachineGunMuzzleFlashRight1', 'DualMachineGunMuzzleFlashRight2']], MiniGun: [['MiniGunMuzzleFlash1']], DualMiniGun: [['DualMiniGunMuzzleFlash1'], ['DualMiniGunMuzzleFlash2']], GrenadeLauncher: [['GrenadeLauncherMuzzleFlash']] };
const BARRELS = { MiniGun: ['MiniGunBarrel'], DualMiniGun: ['DualMiniGunBarrel1', 'DualMiniGunBarrel2'] };
const EFFECT_ORDER = 3;

export class Weapons {
  constructor({ scene, world, RAPIER, fx, sfx, loadGLB, loadTexture, texDirs, shared, carRig, driver, carCollider, carName, upgrades, props, combat, tag, onShot, onTracer, onBoom, onSpark }) {
    Object.assign(this, { scene, world, RAPIER, fx, sfx, loadGLB, loadTexture, texDirs, shared, carRig, driver, carCollider, carName, upgrades, props, combat, tag, onShot, onTracer, onBoom, onSpark });
    this.carMass = driver.car.mass;
    this.equipped = []; this.projectiles = []; this.trails = []; this.nitroMeshes = []; this.nitroOn = false;
    this.nodes = new Map(); this.matCache = new Map(); this._debris = []; this.visuals = []; this.tracerTTL = [];
  }
  async init(p, s) {
    const gltf = await this.loadGLB('Weapons');
    gltf.scene.traverse(o => { if (o.name) this.nodes.set(o.name, o); });
    const first = async (n) => { for (const d of this.texDirs) { const t = await this.loadTexture(d + n + '.png'); if (t) return t; } return null; };
    this.weaponsTex = await first('Weapons_Texture'); this.effectsTex = await first('Effects_Texture'); this.trailTex = await first('RocketTrail_Texture');
    try { const n = await this.loadGLB('Nitro'); const node = n.scene.getObjectByName('Nitro');
      if (node) { this.nitroTex = await first('Nitro_Texture'); this.nitroProto = node.clone(true); this.nitroProto.position.set(0, 0, 0); this.nitroProto.quaternion.identity();
        const mat = new THREE.MeshBasicMaterial({ map: this.nitroTex, color: this.nitroTex ? 0xffffff : 0x66ccff, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide });
        this.nitroProto.traverse(o => { if (o.isMesh) { o.material = mat; o.renderOrder = EFFECT_ORDER; } }); } } catch (e) {}
    if (p && p !== 'None' && p !== 'NoPrimary') this._equip('primary', p);
    if (s && s !== 'None' && s !== 'NoSecondary') this._equip('secondary', s);
    this._mountNitro();
  }
  _material(src) { const name = src.name || '';
    if (!this.matCache.has(name)) { let m;
      if (/Effects/.test(name)) m = new THREE.MeshBasicMaterial({ map: this.effectsTex, color: this.effectsTex ? 0xffffff : 0xffdd88, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide });
      else if (/Laser/.test(name)) m = new THREE.MeshBasicMaterial({ color: 0xff4444, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide });
      else m = new THREE.MeshBasicMaterial({ map: this.weaponsTex, color: this.weaponsTex ? 0xffffff : (src.color ? src.color.clone() : new THREE.Color(1, 1, 1)), side: THREE.DoubleSide });
      this.matCache.set(name, m); }
    return this.matCache.get(name); }
  _clone(name, keepRot) { const node = this.nodes.get(name); if (!node) return null;
    const c = node.clone(true); c.position.set(0, 0, 0); c.scale.set(1, 1, 1);
    if (keepRot) c.quaternion.copy(node.quaternion); else c.quaternion.identity();
    c.traverse(o => { if (o.isMesh) { o.material = this._material(o.material); if (o.material.blending === THREE.AdditiveBlending) o.renderOrder = EFFECT_ORDER; } });
    return c; }
  _equip(kind, key) {
    if (SUPPORTED[kind].indexOf(key) < 0) return;
    const raw = this.shared[kind + 'Weapons'][key]; if (!raw) return;
    const def = lowerKeys(raw);
    const clips = (this.upgrades && this.upgrades[kind] && this.upgrades[kind][0]) || 0;
    const w = { key, kind, type: key.toLowerCase(), def, muzzles: [], flashes: [], tracers: [], flash1Scale: [], bulletScale: [], barrels: [],
      ammo: [def.ammo || 0, def.ammo || 0], clips, clipsMax: clips,
      damage: def.damage || [1, 3], areadamage: def.areadamage || [5, 15, 15], rof: [0, Math.floor(32 / (def.rof || 1))], rofs: null, pod: [0, 2],
      charge: [0, Math.round((def.chargetime || 0) * 32)], fire: 0, chargedDamage: 0, beamLen: 0, spinAngle: 0 };
    const models = MODELS[key], locations = def.location || [1], flashes = FLASHES[key] || [];
    let single = null;
    for (let i = 0; i < locations.length; i++) {
      const modelName = models[Math.min(i, models.length - 1)];
      const dpos = this.carRig.dummies.get(this.carName + (kind === 'primary' ? 'Primary' : 'Secondary') + 'Weapon' + locations[i] + '_Dummy');
      let model;
      if (models.length > 1) { model = this._clone(modelName, true); if (!model) return; if (dpos) model.position.copy(dpos).sub(this.carRig.bodyPos); this.carRig.root.add(model); }
      else { if (!single) { single = this._clone(modelName, true); if (!single) return; this.carRig.root.add(single); } model = single; if (dpos) model.position.copy(dpos).sub(this.carRig.bodyPos); }
      w.model = model;
      const fd = this.nodes.get(key + 'Flash' + (i + 1) + '_Dummy'), src = this.nodes.get(modelName);
      const diff = (fd && src) ? fd.position.clone().sub(src.position) : new THREE.Vector3(0, 1, 0);
      const g = new THREE.Group(); g.position.copy(model.position).add(diff); this.carRig.root.add(g); w.muzzles.push(g);
      const fl = []; for (const fn of (flashes[i] || [])) { const f = this._clone(fn, true); if (f) { f.position.set(0, 0, 0); f.scale.setScalar(0.001); g.add(f); fl.push(f); } }
      w.flashes.push(fl); w.flash1Scale.push(new THREE.Vector3(1, 1, 1)); w.bulletScale.push(1);
      if (/MachineGun|MiniGun/i.test(key)) { const tr = this._clone('Bullet'); if (tr) { tr.visible = false; this.scene.add(tr); w.tracers.push(tr); this.tracerTTL.push(0); } }
    }
    for (const bn of (BARRELS[key] || [])) { const b = this._clone(bn, true), sB = this.nodes.get(bn), sW = this.nodes.get(models[0]); if (b && sB && sW) { b.position.copy(sB.position).sub(sW.position); w.model.add(b); w.barrels.push(b); } }
    if (key === 'Laser') for (const n of ['LaserCharge', 'LaserBeam']) { const m = this._clone(n, true), s = this.nodes.get(n), sW = this.nodes.get('Laser'); if (m && s && sW) { m.position.copy(s.position).sub(sW.position); m.scale.setScalar(0.001); w.model.add(m); } if (n === 'LaserCharge') w.chargeMesh = m; else w.beamMesh = m; }
    if (key === 'DualMachineGun') w.rofs = w.muzzles.map(() => [0, w.rof[1]]);
    this.equipped.push(w);
  }
  _mountNitro() { if (!this.nitroProto) return;
    for (const [name, pos] of this.carRig.dummies) { if (!/Nitro\d+_Dummy$/.test(name)) continue;
      const m = this.nitroProto.clone(true); m.position.copy(pos).sub(this.carRig.bodyPos); m.visible = false; m.renderOrder = EFFECT_ORDER;
      m.traverse(o => { if (o.isMesh) o.renderOrder = EFFECT_ORDER; });
      this.carRig.root.add(m); this.nitroMeshes.push(m); } }
  setNitro(on) { this.nitroOn = on; for (const m of this.nitroMeshes) m.visible = on; }
  hideAll() { for (const w of this.equipped) { if (w.model) w.model.visible = false; for (const g of w.muzzles) g.visible = false; for (const t of w.tracers) t.visible = false; }
    for (const m of this.nitroMeshes) m.visible = false; }
  detach() {
    const vel = this.driver.body.linvel();
    const add = (o) => { const c = o.clone(true); o.getWorldPosition(c.position); o.getWorldQuaternion(c.quaternion); this.scene.add(c);
      const b = this.world.createRigidBody(this.RAPIER.RigidBodyDesc.dynamic().setTranslation(c.position.x, c.position.y, c.position.z).setRotation({ x: c.quaternion.x, y: c.quaternion.y, z: c.quaternion.z, w: c.quaternion.w }).setCcdEnabled(true));
      this.world.createCollider(this.RAPIER.ColliderDesc.ball(0.3).setMass(15).setRestitution(0.3).setFriction(0.6), b);
      b.setLinvel({ x: vel.x * 0.7 + rand(-4, 4), y: vel.y * 0.7 + rand(-4, 4), z: rand(4, 9) }, true);
      b.setAngvel({ x: rand(-6, 6), y: rand(-6, 6), z: rand(-6, 6) }, true);
      this._debris.push({ mesh: c, body: b }); };
    for (const w of this.equipped) { if (w.model) { w.model.traverse(o => { if (o.isMesh) add(o); }); w.model.visible = false; }
      for (const g of w.muzzles) { g.traverse(o => { if (o.isMesh) add(o); }); g.visible = false; }
      for (const t of w.tracers) t.visible = false; }
    for (const m of this.nitroMeshes) m.visible = false;
    this.clearVisuals();
  }
  cleanup() { for (const d of this._debris) { this.scene.remove(d.mesh); this.world.removeRigidBody(d.body); } this._debris.length = 0;
    for (const w of this.equipped) { if (w.model) w.model.visible = true; for (const g of w.muzzles) g.visible = true; } }
  updateDebris() { for (const d of this._debris) { const t = d.body.translation(), r = d.body.rotation(); d.mesh.position.set(t.x, t.y, t.z); d.mesh.quaternion.set(r.x, r.y, r.z, r.w); } }
  _ray(o, d, m) { const h = this.world.castRayAndGetNormal(new this.RAPIER.Ray(o, d), m || 1000, true, undefined, undefined, this.carCollider, this.driver.body); if (!h) return null; const t = h.timeOfImpact !== undefined ? h.timeOfImpact : h.toi; return { toi: t, normal: h.normal, collider: h.collider }; }
  _muzzle(g) { const origin = g.getWorldPosition(new THREE.Vector3()); const quat = g.getWorldQuaternion(new THREE.Quaternion()); return { origin, quat, dir: new THREE.Vector3(0, 1, 0).applyQuaternion(quat) }; }
  _useAmmo(w) { w.ammo[0]--; if (w.ammo[0] <= 0 && w.clips > 0) { w.ammo[0] = w.ammo[1]; w.clips--; } }
  _hit(h, p, d) {
    const pr = this.props.byCollider.get(h.collider.handle);
    if (pr) {
      this.props.damage(pr, d, this.tag); this.sfx.hit(pr.type || 'none', p); this.fx.spark(p);
      if (this.onSpark) this.onSpark(p.toArray(), pr.type || 'none');
      return;
    }
    const car = this.combat && this.combat.byCollider.get(h.collider.handle);
    if (car && car.tag !== this.tag) {
      this.combat.damage(car, d); this.sfx.hit('metal', p); this.fx.spark(p);
      if (this.onSpark) this.onSpark(p.toArray(), 'metal');
    }
  }
  _fireGun(w, mi) {
    const mz = this._muzzle(w.muzzles[mi]); const hit = this._ray(mz.origin, mz.dir); const dist = hit ? hit.toi : 100;
    const tr = w.tracers[mi]; if (tr) { tr.visible = true; tr.position.copy(mz.origin).addScaledVector(mz.dir, dist); tr.quaternion.copy(mz.quat); tr.scale.set(1, Math.max(dist, 0.001), 1); }
    w.bulletScale[mi] = dist;
    if (hit) this._hit(hit, mz.origin.clone().addScaledVector(mz.dir, hit.toi), randInt(w.damage[0], w.damage[1]));
    const fl = w.flashes[mi];
    if (fl[0]) { const r = rand(1, 1.4); w.flash1Scale[mi].set(r, r * 1.5, r); fl[0].scale.copy(w.flash1Scale[mi]); fl[0].rotation.y = D2R(randInt(1, 45)); }
    if (fl[1]) { fl[1].scale.setScalar(1.5); fl[1].rotation.y = D2R(randInt(1, 120)); }
    if (!/MiniGun/i.test(w.key)) this.sfx.playAt('MachineGun_SFX', mz.origin, { volume: 0.4, rate: rand(0.95, 1.05), throttle: 45, mono: true });
    if (this.onTracer) this.onTracer(mi, mz.origin.toArray(), mz.quat.toArray(), dist, /MiniGun/i.test(w.key));
  }
  _gunFade(w, mi, c, th) { const p = Math.max(1 - c / th, 0.001); const fl = w.flashes[mi];
    if (fl[0]) fl[0].scale.copy(w.flash1Scale[mi]).multiplyScalar(p);
    if (fl[1]) { const h = th * 0.5; const p2 = Math.max(c <= h ? 1 - c / h : (c - h) / h, 0.001); fl[1].scale.setScalar(1.4 * p2); }
    const tr = w.tracers[mi]; if (tr) { const s = Math.max(w.bulletScale[mi] * p, 0.001); tr.scale.y = s; tr.visible = s > 0.01; } }
  _gunIdle(w) { for (let mi = 0; mi < w.muzzles.length; mi++) { for (const f of w.flashes[mi]) f.scale.setScalar(0.001); if (w.tracers[mi]) w.tracers[mi].visible = false; } }
  _explode(p, ad, dur, snd) {
    this.fx.explosion(p, { duration: dur });
    this.sfx.playAt(snd || 'RocketPodExplosion_SFX', p, { volume: 0.8, throttle: 80 });
    this.areaDamage(p, ad, this.tag);
    if (this.onBoom) this.onBoom(p.toArray(), dur, 1, snd || 'RocketPodExplosion_SFX');
  }
  _update_machinegun(w, inp) { if (inp.action1) { if (w.ammo[0] > 0) { w.rof[0]++; if (w.rof[0] >= w.rof[1]) { w.rof[0] = 0; this._useAmmo(w); this._fireGun(w, 0); } else this._gunFade(w, 0, w.rof[0], w.rof[1]); } else this._gunIdle(w); } else { this._gunIdle(w); w.rof[0] = w.rof[1]; } }
  _update_dualmachinegun(w, inp) { for (let mi = 0; mi < 2; mi++) { const r = w.rofs[mi];
    if (inp.action1) { if (w.ammo[0] > 0) { r[0]++; if (r[0] >= r[1]) { r[0] = 0; this._useAmmo(w); this._fireGun(w, mi); } else this._gunFade(w, mi, r[0], r[1]); } else this._gunIdle(w); }
    else { for (const f of w.flashes[mi]) f.scale.setScalar(0.001); if (w.tracers[mi]) w.tracers[mi].visible = false; r[0] = mi === 0 ? r[1] * 0.5 : r[1]; } } }
  _update_minigun(w, i) { this._minigunTick(w, i, 1); }
  _update_dualminigun(w, i) { this._minigunTick(w, i, 2); }
  _minigunTick(w, inp, guns) {
    const spin = () => { for (const b of w.barrels) b.rotateY(D2R(w.charge[0])); w.spinAngle = (w.spinAngle + w.charge[0]) % 360; };
    if (inp.action1) { if (w.charge[0] < w.charge[1]) { w.charge[0]++; spin(); this._gunIdle(w); this.sfx.stopLoop('MiniGun_SFX'); return; }
      spin();
      if (w.ammo[0] > 0) { w.rof[0]++; if (w.rof[0] >= w.rof[1]) { w.rof[0] = 0; for (let mi = 0; mi < guns; mi++) { this._useAmmo(w); this._fireGun(w, mi); } } else for (let mi = 0; mi < guns; mi++) this._gunFade(w, mi, w.rof[0], w.rof[1]); } else this._gunIdle(w); }
    else { w.charge[0] = Math.max(0, w.charge[0] - 1); spin(); this._gunIdle(w); w.rof[0] = w.rof[1]; }
    const firing = inp.action1 && w.charge[0] >= w.charge[1] && w.ammo[0] > 0;
    if (firing) this.sfx.startLoop('MiniGun_SFX', { volume: 0.3 }); else this.sfx.stopLoop('MiniGun_SFX');
  }
  _update_laser(w, inp) {
    if (inp.action1) { if (w.charge[0] < w.charge[1]) { w.charge[0]++; w.chargedDamage = w.damage[1] * (w.charge[0] / w.charge[1]); if (w.chargeMesh) w.chargeMesh.scale.setScalar(Math.max(w.charge[0] / w.charge[1], 0.001)); w.fire = 1; } }
    else if (w.fire === 1 && w.chargedDamage > 0) { w.chargedDamage -= 0.5;
      if (w.chargedDamage <= 0) { w.fire = 0; w.charge[0] = 0; w.chargedDamage = 0; w.beamLen = 0; if (w.chargeMesh) w.chargeMesh.scale.setScalar(0.001); if (w.beamMesh) w.beamMesh.scale.setScalar(0.001); }
      else { const p = w.chargedDamage / w.damage[1]; if (w.chargeMesh) w.chargeMesh.scale.setScalar(p);
        const mz = this._muzzle(w.muzzles[0]); const h = this._ray(mz.origin, mz.dir);
        w.beamLen = h ? h.toi : 100;
        if (w.beamMesh) w.beamMesh.scale.set(p, w.beamLen * 10, p);
        if (h) this._hit(h, mz.origin.clone().addScaledVector(mz.dir, h.toi), w.chargedDamage); } }
    else { w.beamLen = 0; }
  }
  _update_rocketpod(w, inp) { if (inp.action2) { w.rof[0]++; if (w.rof[0] >= w.rof[1]) { w.rof[0] = 0; if (w.ammo[0] > 0) { this._useAmmo(w); w.pod[0]++; if (w.pod[0] > w.pod[1]) w.pod[0] = 1; this._spawnRocket(w, w.pod[0] - 1); } } } else w.rof[0] = w.rof[1]; }
  _update_minedeployer(w, inp) { if (inp.action2) { w.rof[0]++; if (w.rof[0] >= w.rof[1]) { w.rof[0] = 0; if (w.ammo[0] > 0) { this._useAmmo(w); this._spawnMine(w); } } } else w.rof[0] = w.rof[1]; }
  _update_grenadedeployer(w, inp) { if (inp.action2) { w.rof[0]++; if (w.rof[0] >= w.rof[1]) { w.rof[0] = 0; if (w.ammo[0] > 0) { w.ammo[0] = Math.max(0, w.ammo[0] - 5); if (w.ammo[0] === 0 && w.clips > 0) { w.ammo[0] = w.ammo[1]; w.clips--; } this._spawnCluster(w); } } } else w.rof[0] = w.rof[1]; }
  _update_grenadelauncher(w, inp) { const fl = w.flashes[0][0];
    const fade = () => { if (!fl) return; if (w.rof[0] <= 3) { const p = Math.max(1 - w.rof[0] / 3, 0.001); const s = Math.max(w.flash1Scale[0].x * p, 0.001); fl.scale.set(s, s * 5, s); } else fl.scale.setScalar(0.001); };
    if (inp.action2) { if (w.ammo[0] > 0) { w.rof[0]++; if (w.rof[0] >= w.rof[1]) { w.rof[0] = 0; this._useAmmo(w); const r = rand(2, 2.4); w.flash1Scale[0].set(r, r * 1.5, r); if (fl) { fl.scale.copy(w.flash1Scale[0]); fl.rotation.y = D2R(randInt(1, 45)); } this._spawnGrenade(w); } else fade(); } else fade(); }
    else { fade(); w.rof[0] = w.rof[1]; } }
  _spawnRocket(w, mi) { const mz = this._muzzle(w.muzzles[mi]); const mesh = this._clone('Rocket'); if (!mesh) return;
    mesh.position.copy(mz.origin); mesh.quaternion.copy(mz.quat); this.scene.add(mesh);
    const fl = this._clone('RocketFlame'); if (fl) { fl.position.set(0, -0.5, 0); mesh.add(fl); }
    const tr = this._newTrail(mz.origin, mz.quat);
    this.projectiles.push({ kind: 'rocket', mesh, flame: fl, trail: tr, speed: 5, distance: 0, timeout: 128, areadamage: w.areadamage, owner: this.tag });
    this.sfx.playAt('RocketPodLaunch_SFX', mz.origin, { volume: 0.6 });
    if (this.onShot) this.onShot('rocket', { o: mz.origin.toArray(), q: mz.quat.toArray() }); }
  _newTrail(pos, quat) { const MP = 130; const geo = new THREE.BufferGeometry();
    const pa = new Float32Array(MP * 6), ua = new Float32Array(MP * 4), ia = new Uint16Array(MP * 6);
    geo.setAttribute('position', new THREE.BufferAttribute(pa, 3).setUsage(THREE.DynamicDrawUsage));
    geo.setAttribute('uv', new THREE.BufferAttribute(ua, 2).setUsage(THREE.DynamicDrawUsage));
    geo.setIndex(new THREE.BufferAttribute(ia, 1)); geo.setDrawRange(0, 0);
    const mat = new THREE.MeshBasicMaterial({ map: this.trailTex, color: this.trailTex ? 0xffffff : 0xffaa66, transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending });
    const mesh = new THREE.Mesh(geo, mat); mesh.frustumCulled = false; mesh.renderOrder = EFFECT_ORDER; this.scene.add(mesh);
    const tr = { mesh, geo, mat, spawnPos: pos.clone(), spawnQuat: quat.clone(), posArr: pa, uvArr: ua, idxArr: ia, pairs: 0, maxPairs: MP, fade: 1, dead: false };
    this._trailPair(tr, 0); this.trails.push(tr); return tr; }
  _trailPair(tr, d) { if (tr.pairs >= tr.maxPairs) return;
    for (const s of [1, -1]) { const v = new THREE.Vector3(0.25, d, s * 0.4).applyQuaternion(tr.spawnQuat).add(tr.spawnPos);
      const n = tr.pairs * 2 + (s > 0 ? 0 : 1);
      tr.posArr[n * 3] = v.x; tr.posArr[n * 3 + 1] = v.y; tr.posArr[n * 3 + 2] = v.z;
      tr.uvArr[n * 2] = s > 0 ? 0 : 1; tr.uvArr[n * 2 + 1] = d * 0.2; }
    tr.pairs++; const k = tr.pairs - 1;
    if (k >= 1) { const i = 2 * k - 2, b = (k - 1) * 6; tr.idxArr[b] = i; tr.idxArr[b + 1] = i + 2; tr.idxArr[b + 2] = i + 3; tr.idxArr[b + 3] = i; tr.idxArr[b + 4] = i + 3; tr.idxArr[b + 5] = i + 1; }
    tr.geo.attributes.position.needsUpdate = true; tr.geo.attributes.uv.needsUpdate = true; tr.geo.index.needsUpdate = true; tr.geo.setDrawRange(0, k * 6); }
  _spawnMine(w) { const mz = this._muzzle(w.muzzles[0]); const dir = new THREE.Vector3(0, 0, -1).applyQuaternion(this.carRig.root.quaternion);
    const h = this._ray(mz.origin, dir, 100); if (!h) return;
    const point = mz.origin.clone().addScaledVector(dir, h.toi); const mesh = this._clone('Mine'); if (!mesh) return; mesh.position.copy(point);
    const zA = new THREE.Vector3(h.normal.x, h.normal.y, h.normal.z).normalize(); let ref = new THREE.Vector3(0, 1, 0); if (Math.abs(ref.dot(zA)) > 0.99) ref = new THREE.Vector3(1, 0, 0);
    const xA = new THREE.Vector3().crossVectors(ref, zA).normalize(), yA = new THREE.Vector3().crossVectors(zA, xA);
    mesh.quaternion.setFromRotationMatrix(new THREE.Matrix4().makeBasis(xA, yA, zA)); this.scene.add(mesh);
    this.projectiles.push({ kind: 'mine', mesh, pos: point, timeout: PERSIST, arm: 32, range: w.def.range || 3, areadamage: w.areadamage, owner: this.tag });
    this.sfx.playAt('Mine1_SFX', point, { volume: 0.6 });
    if (this.onShot) this.onShot('mine', { o: point.toArray(), q: mesh.quaternion.toArray(), r: w.def.range || 3 }); }
  _spawnCluster(w) { this.projectiles.push({ kind: 'cluster', left: 5, counter: 0, grenades: [], allSpawned: false, timeout: 800, muzzle: w.muzzles[0], range: w.def.range || 3, areadamage: w.areadamage, owner: this.tag }); }
  _spawnGrenade(w) { const mz = this._muzzle(w.muzzles[0]);
    const origin = mz.origin.clone().addScaledVector(mz.dir, 6);
    const mesh = this._clone('Grenade'); if (!mesh) return; mesh.position.copy(origin); mesh.quaternion.copy(mz.quat); this.scene.add(mesh);
    const gb = this.world.createRigidBody(this.RAPIER.RigidBodyDesc.dynamic().setTranslation(origin.x, origin.y, origin.z).setRotation({ x: mz.quat.x, y: mz.quat.y, z: mz.quat.z, w: mz.quat.w }).setLinvel(mz.dir.x * 100, mz.dir.y * 100, mz.dir.z * 100).setCcdEnabled(true));
    this.world.createCollider(this.RAPIER.ColliderDesc.ball(0.25).setMass(20).setRestitution(0.9).setFriction(0.5), gb);
    this.projectiles.push({ kind: 'grenade', mesh, body: gb, timeout: 64, puff: 0, areadamage: w.areadamage, owner: this.tag });
    this.sfx.playAt('GrenadeLauncher' + randInt(1, 3) + '_SFX', origin, { volume: 0.6 });
    if (this.onShot) this.onShot('grenade', { o: origin.toArray(), q: mz.quat.toArray(), v: [mz.dir.x * 100, mz.dir.y * 100, mz.dir.z * 100] }); }
  _removeProjectile(p, i) { if (p.mesh) this.scene.remove(p.mesh); if (p.body) this.world.removeRigidBody(p.body); if (p.trail) p.trail.dead = true;
    if (p.grenades) for (const g of p.grenades) { this.scene.remove(g.mesh); this.world.removeRigidBody(g.body); }
    this.projectiles.splice(i, 1); }
  _targets() { return (this.combat ? this.combat.cars() : []).filter(c => c.tag !== this.tag && !c.dead); }
  _updateProjectiles() {
    const targets = this._targets();
    const near = (pos, r) => targets.some(c => { const t = c.body.translation(); return Math.hypot(t.x - pos.x, t.y - pos.y, t.z - pos.z) <= r; });
    for (let i = this.projectiles.length - 1; i >= 0; i--) { const p = this.projectiles[i];
      if (p.kind === 'rocket') { p.mesh.translateY(p.speed); p.mesh.rotateY(D2R(25)); p.distance += p.speed; if (p.flame) p.flame.scale.setScalar(rand(1, 3)); this._trailPair(p.trail, p.distance);
        const dir = new THREE.Vector3(0, 1, 0).applyQuaternion(p.mesh.quaternion); const h = this._ray(p.mesh.position, dir, 2000); let boom = false;
        if (h && h.toi < 0.75 + p.speed) { this._explode(p.mesh.position.clone().addScaledVector(dir, h.toi), p.areadamage, 1500); boom = true; }
        p.timeout--; if (boom || p.timeout <= 0) { p.trail.dead = true; this.scene.remove(p.mesh); this.projectiles.splice(i, 1); } }
      else if (p.kind === 'mine') { if (p.arm > 0) p.arm--; const n = p.arm <= 0 && near(p.pos, p.range);
        if (n) this._explode(p.pos, p.areadamage, 500, 'MineGrenadeExplosion_SFX');
        if (n) this._removeProjectile(p, i); }
      else if (p.kind === 'grenade') { const t = p.body.translation(), r = p.body.rotation(); p.mesh.position.set(t.x, t.y, t.z); p.mesh.quaternion.set(r.x, r.y, r.z, r.w);
        p.timeout--; p.puff++; if (p.puff >= 2) { p.puff = 0; this.fx.puff(p.mesh.position); }
        const n = near(p.mesh.position, 4.0); if (n || p.timeout <= 0) { this._explode(p.mesh.position.clone(), p.areadamage, 500, 'GrenadeExplosion_SFX'); this._removeProjectile(p, i); } }
      else if (p.kind === 'cluster') { p.counter++; p.timeout--;
        if (p.counter >= 2 && p.left > 0) { p.counter = 0; p.left--; const o = p.muzzle.getWorldPosition(new THREE.Vector3()); const mesh = this._clone('Grenade1');
          if (mesh) { mesh.position.copy(o); mesh.rotation.set(rand(0, 3), rand(0, 3), rand(0, 3)); this.scene.add(mesh);
            const b = this.world.createRigidBody(this.RAPIER.RigidBodyDesc.dynamic().setTranslation(o.x, o.y, o.z).setCcdEnabled(true));
            this.world.createCollider(this.RAPIER.ColliderDesc.ball(0.45).setMass(20).setRestitution(0.75).setFriction(0.5), b);
            const imp = { x: rand(-0.5, 0.5) * 500, y: rand(0.2, 0.7) * 500, z: rand(-0.5, 0.5) * 500 };
            b.applyImpulse(imp, true);
            p.grenades.push({ mesh, body: b }); this.sfx.playAt('Grenade' + randInt(1, 5) + '_SFX', o, { volume: 0.4 });
            if (this.onShot) this.onShot('caltrop', { o: o.toArray(), v: [imp.x / 20, imp.y / 20, imp.z / 20] }); }
          if (p.left === 0) p.allSpawned = true; }
        let rem = false;
        if (p.allSpawned) { for (let j = p.grenades.length - 1; j >= 0; j--) { const g = p.grenades[j]; const t = g.body.translation(), r = g.body.rotation(); g.mesh.position.set(t.x, t.y, t.z); g.mesh.quaternion.set(r.x, r.y, r.z, r.w);
            if (near(g.mesh.position, p.range)) { this._explode(g.mesh.position.clone(), p.areadamage, 500, 'MineGrenadeExplosion_SFX'); this.scene.remove(g.mesh); this.world.removeRigidBody(g.body); p.grenades.splice(j, 1); } }
          if (p.grenades.length === 0) rem = true; }
        if (p.timeout <= 0) rem = true; if (rem) this._removeProjectile(p, i); } }
    for (let i = this.trails.length - 1; i >= 0; i--) { const tr = this.trails[i]; if (tr.dead) { tr.fade -= 0.05; tr.mat.opacity = Math.max(tr.fade, 0); if (tr.fade <= 0) { this.scene.remove(tr.mesh); tr.geo.dispose(); tr.mat.dispose(); this.trails.splice(i, 1); } } } }

  // ---------- ghost-side visual replicas (no damage, no physics bodies) ----------
  spawnVisual(kind, d) {
    const o = new THREE.Vector3().fromArray(d.o), q = new THREE.Quaternion().fromArray(d.q || [0, 0, 0, 1]);
    if (kind === 'rocket') {
      const mesh = this._clone('Rocket'); if (!mesh) return;
      mesh.position.copy(o); mesh.quaternion.copy(q); this.scene.add(mesh);
      const fl = this._clone('RocketFlame'); if (fl) { fl.position.set(0, -0.5, 0); mesh.add(fl); }
      this.visuals.push({ kind, mesh, flame: fl, trail: this._newTrail(o, q), distance: 0, timeout: 132 });
      this.sfx.playAt('RocketPodLaunch_SFX', o, { volume: 0.5 });
    } else if (kind === 'grenade') {
      const mesh = this._clone('Grenade'); if (!mesh) return;
      mesh.position.copy(o); mesh.quaternion.copy(q); this.scene.add(mesh);
      this.visuals.push({ kind, mesh, v: new THREE.Vector3().fromArray(d.v || [0, 0, 0]), timeout: 70, puff: 0 });
    } else if (kind === 'caltrop') {
      const mesh = this._clone('Grenade1'); if (!mesh) return;
      mesh.position.copy(o); mesh.rotation.set(rand(0, 3), rand(0, 3), rand(0, 3)); this.scene.add(mesh);
      this.visuals.push({ kind, mesh, v: new THREE.Vector3().fromArray(d.v || [0, 0, 8]), timeout: 800,
        spin: new THREE.Vector3(rand(-5, 5), rand(-5, 5), rand(-5, 5)), rest: false });
      this.sfx.playAt('Grenade1_SFX', o, { volume: 0.35, throttle: 60 });
    } else if (kind === 'mine') {
      const mesh = this._clone('Mine'); if (!mesh) return;
      mesh.position.copy(o); mesh.quaternion.copy(q); this.scene.add(mesh);
      this.visuals.push({ kind, mesh, timeout: PERSIST });
      this.sfx.playAt('Mine1_SFX', o, { volume: 0.5 });
    }
  }
  _dropVisual(v) { this.scene.remove(v.mesh); if (v.trail) v.trail.dead = true; }
  removeVisualsNear(p, r) {
    for (let i = this.visuals.length - 1; i >= 0; i--) {
      const v = this.visuals[i];
      if (v.kind !== 'caltrop' && v.kind !== 'mine' && v.kind !== 'grenade') continue;
      if (v.mesh.position.distanceTo(p) <= r) { this._dropVisual(v); this.visuals.splice(i, 1); }
    }
  }
  showTracer(mi, o, q, dist, mini) {
    const w = this.equipped[0]; if (!w || !w.tracers[mi]) return;
    const tr = w.tracers[mi];
    tr.quaternion.fromArray(q);
    const dir = new THREE.Vector3(0, 1, 0).applyQuaternion(tr.quaternion);
    tr.position.fromArray(o).addScaledVector(dir, dist);
    tr.scale.set(1, Math.max(dist, 0.001), 1);
    tr.visible = true;
    this.tracerTTL[mi] = 3;
    const fl = w.flashes[mi];
    if (fl && fl[0]) { const r = rand(1, 1.4); fl[0].scale.set(r, r * 1.5, r); fl[0].rotation.y = D2R(randInt(1, 45)); }
    if (fl && fl[1]) fl[1].scale.setScalar(1.5);
    if (!mini) this.sfx.playAt('MachineGun_SFX', new THREE.Vector3().fromArray(o), { volume: 0.35, rate: rand(0.95, 1.05), throttle: 45, mono: true });
  }
  setLaser(c, f, len) {
    const w = this.equipped.find(x => x.type === 'laser'); if (!w) return;
    if (w.chargeMesh) w.chargeMesh.scale.setScalar(Math.max(c || 0, 0.001));
    if (w.beamMesh) { if (f && len > 0) w.beamMesh.scale.set(Math.max(c, 0.05), len * 10, Math.max(c, 0.05)); else w.beamMesh.scale.setScalar(0.001); }
  }
  setBarrels(angle) { for (const w of this.equipped) for (const b of w.barrels) b.rotation.y = D2R(angle || 0); }
  // called once per 32 Hz game tick so replica lifetimes match the owner exactly
  updateVisuals() {
    const dt = 1 / 32;
    for (let i = this.visuals.length - 1; i >= 0; i--) {
      const v = this.visuals[i]; if (v.timeout < PERSIST) v.timeout--;
      if (v.kind === 'rocket') {
        v.mesh.translateY(5); v.mesh.rotateY(D2R(25)); v.distance += 5;
        if (v.flame) v.flame.scale.setScalar(rand(1, 3));
        this._trailPair(v.trail, v.distance);
      } else if (v.kind === 'grenade' || v.kind === 'caltrop') {
        if (!v.rest) {
          v.v.z += GRAV * dt;
          v.mesh.position.addScaledVector(v.v, dt);
          if (v.spin) { v.mesh.rotation.x += v.spin.x * dt; v.mesh.rotation.y += v.spin.y * dt; v.mesh.rotation.z += v.spin.z * dt; }
          if (this.world && this.RAPIER) {
            const h = this.world.castRay(new this.RAPIER.Ray({ x: v.mesh.position.x, y: v.mesh.position.y, z: v.mesh.position.z }, { x: 0, y: 0, z: -1 }), 0.55, true);
            if (h && v.v.z < 0) {
              const toi = h.timeOfImpact !== undefined ? h.timeOfImpact : h.toi;
              v.mesh.position.z -= Math.max(0, toi - 0.45);
              v.v.z = -v.v.z * 0.4; v.v.x *= 0.62; v.v.y *= 0.62;
              if (v.spin) v.spin.multiplyScalar(0.6);
              if (Math.abs(v.v.z) < 1.2 && Math.hypot(v.v.x, v.v.y) < 1.2) { v.rest = true; v.v.set(0, 0, 0); }
            }
          }
          if (v.kind === 'grenade') { v.puff++; if (v.puff >= 3) { v.puff = 0; this.fx.puff(v.mesh.position); } }
        }
      }
      if (v.timeout <= 0) { this._dropVisual(v); this.visuals.splice(i, 1); }
    }
    for (let i = this.trails.length - 1; i >= 0; i--) { const tr = this.trails[i]; if (tr.dead) { tr.fade -= 0.05; tr.mat.opacity = Math.max(tr.fade, 0); if (tr.fade <= 0) { this.scene.remove(tr.mesh); tr.geo.dispose(); tr.mat.dispose(); this.trails.splice(i, 1); } } }
    const w = this.equipped[0];
    if (w) for (let mi = 0; mi < w.tracers.length; mi++) {
      if (this.tracerTTL[mi] > 0) { this.tracerTTL[mi]--; if (this.tracerTTL[mi] <= 0) { w.tracers[mi].visible = false; for (const f of w.flashes[mi]) f.scale.setScalar(0.001); } }
    }
  }
  clearVisuals() { for (const v of this.visuals) this._dropVisual(v); this.visuals.length = 0; }

  areaDamage(pos, data, sender) { const min = data[0], max = data[1], rad = data[2], offz = pos.z - 4.5;
    for (const p of this.props.props) { if (!p.alive) continue; const t = p.body.translation(); const d = Math.hypot(t.x - pos.x, t.y - pos.y, t.z - pos.z); if (d > rad) continue;
      const perc = 1 - d / rad; this.props.damage(p, min + (max - min) * perc, sender);
      if (p.alive && !p.static) { let vx = t.x - pos.x, vy = t.y - pos.y, vz = t.z - offz; const l = Math.hypot(vx, vy, vz) || 1; vx /= l; vy /= l; vz /= l; const k = p.mass * 3 * perc;
        p.body.applyImpulse({ x: vx * k, y: vy * k, z: vz * k * 2 }, true); p.body.applyTorqueImpulse({ x: vx * 10000, y: vy * 10000, z: 0 }, true); } }
    if (this.combat) for (const c of this.combat.cars()) {
      if (c.tag === sender || c.dead) continue;
      const t = c.body.translation(); const d = Math.hypot(t.x - pos.x, t.y - pos.y, t.z - pos.z); if (d > rad) continue;
      const perc = 1 - d / rad; this.combat.damage(c, min + (max - min) * perc);
      let vx = t.x - pos.x, vy = t.y - pos.y, vz = t.z - offz; const l = Math.hypot(vx, vy, vz) || 1; vx /= l; vy /= l; vz /= l;
      const k = c.car.mass * perc;
      c.body.applyImpulse({ x: vx * k, y: vy * k, z: vz * k * 2 }, true); c.body.applyTorqueImpulse({ x: vx * 10000, y: vy * 10000, z: 0 }, true); } }
  update(inp) { this.carRig.root.updateMatrixWorld(true);
    for (const w of this.equipped) { const fn = this['_update_' + w.type]; if (fn) fn.call(this, w, inp); }
    this._updateProjectiles();
    if (this.nitroOn) for (const m of this.nitroMeshes) m.scale.setScalar(rand(0.8, 1.3)); }
  ammoInfo() { return this.equipped.map(w => ({ name: w.def.name || w.key, ammo: Math.max(0, w.ammo[0]), clips: w.clips, clipsMax: w.clipsMax, max: w.ammo[1] })); }
  laserState() { const w = this.equipped.find(x => x.type === 'laser'); if (!w) return null;
    return { c: w.charge[1] ? w.charge[0] / w.charge[1] : 0, f: w.fire, l: w.beamLen || 0 }; }
  barrelAngle() { const w = this.equipped.find(x => x.barrels.length); return w ? (w.spinAngle || 0) : 0; }
}