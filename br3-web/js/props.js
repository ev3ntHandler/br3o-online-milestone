// props.js – track props + pickups, with network sync hooks (destroy / detonate).
import * as THREE from 'three';
import { parseLingo, parseEventsFile, plain } from './lingo.js';

export async function loadSharedData(fetchText, DATA) {
  const ev = parseEventsFile(await fetchText(DATA + 'Shared/SharedData.txt'));
  const block = (name) => { const out = {};
    for (const c of ev.blocks[name] || []) { if (!c.fields.length || c.cmd.indexOf('//') === 0) continue; out[c.cmd] = plain(parseLingo(c.fields[0])); }
    return out; };
  return { physicsObjects: block('PhysicsObjects'), primaryWeapons: block('PrimaryWeapons'), secondaryWeapons: block('SecondaryWeapons') };
}
export function dataQuat(q) {
  const w = Math.max(-1, Math.min(1, q[3]));
  const s = Math.sqrt(Math.max(0, 1 - w * w));
  const angle = 2 * Math.atan2(s, w);
  const axis = s < 1e-6 ? new THREE.Vector3(0, 1, 0) : new THREE.Vector3(q[0] / s, q[2] / s, q[1] / s);
  return new THREE.Quaternion().setFromAxisAngle(axis.normalize(), angle);
}
const HIDDEN_KEY = 'br3.hiddenPackages';
function hiddenList() { try { return JSON.parse(localStorage.getItem(HIDDEN_KEY) || '[]'); } catch (e) { return []; } }

export class Props {
  constructor({ scene, world, RAPIER, fx, sfx, loadGLB, loadTexture, texDirs, shared, trackKey, onPickup, onScore, onAreaDamage, onSync }) {
    Object.assign(this, { scene, world, RAPIER, fx, sfx, loadGLB, loadTexture, texDirs, shared, trackKey, onPickup, onScore, onAreaDamage, onSync });
    this.props = []; this.pickups = []; this.byCollider = new Map(); this.schedule = [];
    this.protos = new Map(); this.pickupProtos = new Map();
    this._v1 = new THREE.Vector3(); this._v2 = new THREE.Vector3(); this._v3 = new THREE.Vector3(); this._m = new THREE.Matrix4();
  }
  async init() {
    const first = async (n) => { for (const d of this.texDirs) { const t = await this.loadTexture(d + n + '.png'); if (t) return t; } return null; };
    const matCache = new Map();
    const matFor = async (src, pickup) => {
      const key = (src.name || '') + (pickup ? '#p' : '#o');
      if (!matCache.has(key)) {
        const texName = src.userData && src.userData.texture;
        const map = texName ? await first(texName) : null;
        matCache.set(key, new THREE.MeshBasicMaterial({ map, color: map ? 0xffffff : (src.color ? src.color.clone() : new THREE.Color(1, 1, 1)), side: THREE.DoubleSide, transparent: pickup, alphaTest: pickup ? 0.1 : 0.5 }));
      }
      return matCache.get(key);
    };
    const grab = async (glbName, pickup) => {
      const gltf = await this.loadGLB(glbName); const out = new Map();
      for (const node of gltf.scene.children) {
        if (!node.name || node.name === 'DefaultView' || node.name === 'Default MAX Light') continue;
        let hasMesh = false; node.traverse(o => { if (o.isMesh) hasMesh = true; });
        if (!hasMesh) continue;
        const proto = node.clone(true); proto.position.set(0, 0, 0); proto.quaternion.identity(); proto.scale.set(1, 1, 1);
        const jobs = []; proto.traverse(o => { if (o.isMesh) jobs.push((async () => { o.material = await matFor(o.material, pickup); })()); });
        await Promise.all(jobs); out.set(node.name, proto);
      }
      return out;
    };
    this.protos = await grab('Objects', false);
    this.pickupProtos = await grab('PickUps', true);
  }
  build(tiles, { props: useProps = true, pickups: usePickups = true } = {}) {
    tiles.forEach((tile, idx) => {
      if (tile.deco) return;
      for (const key of Object.keys(tile)) {
        if (/object/i.test(key)) { if (useProps) this._spawnProp(key, tile[key], idx); }
        else if (/pickup/i.test(key)) { if (usePickups) this._spawnPickup(key, tile[key], idx); }
      }
    });
  }
  _geomVerts(proto) { let arr = null; proto.traverse(o => { if (o.isMesh && !arr) arr = o.geometry.attributes.position.array; }); return arr ? new Float32Array(arr) : new Float32Array(0); }
  _spawnProp(kind, list, tileIndex) {
    const proto = this.protos.get(kind); if (!proto || !Array.isArray(list)) return;
    const def = this.shared.physicsObjects[kind] || this.shared.physicsObjects.Default_Object || {};
    const isStatic = def.weight === 'static';
    const mass = isStatic ? 0 : Number(def.weight) || 100;
    const health = typeof def.health === 'number' ? def.health : Infinity;
    const verts = this._geomVerts(proto);
    for (const entry of list) {
      const pos = entry[0], q = entry[1] || [0, 0, 0, 1];
      const mesh = proto.clone(true);
      mesh.position.set(pos.x, pos.y, pos.z); mesh.quaternion.copy(dataQuat(q)); mesh.name = kind;
      this.scene.add(mesh);
      const rot = { x: mesh.quaternion.x, y: mesh.quaternion.y, z: mesh.quaternion.z, w: mesh.quaternion.w };
      const desc = isStatic ? this.RAPIER.RigidBodyDesc.fixed() : this.RAPIER.RigidBodyDesc.dynamic();
      desc.setTranslation(pos.x, pos.y, pos.z).setRotation(rot);
      const body = this.world.createRigidBody(desc);
      let cd;
      if (isStatic) { const idx = new Uint32Array(verts.length / 3); for (let i = 0; i < idx.length; i++) idx[i] = i; cd = this.RAPIER.ColliderDesc.trimesh(verts, idx); }
      else { cd = this.RAPIER.ColliderDesc.convexHull(verts) || this.RAPIER.ColliderDesc.ball(0.5); cd.setMass(mass); }
      cd.setFriction(isStatic ? 0.1 : 0.9).setRestitution(isStatic ? 0.1 : 0.9);
      const collider = this.world.createCollider(cd, body);
      const rec = { idx: this.props.length, kind, mesh, body, collider, tileIndex, alive: true, static: isStatic, mass, health, score: Number(def.score) || 0, type: def.type || 'none', effect: def.effect || null,
        pp: new THREE.Vector3(pos.x, pos.y, pos.z), pq: mesh.quaternion.clone(), cp: new THREE.Vector3(pos.x, pos.y, pos.z), cq: mesh.quaternion.clone() };
      this.props.push(rec); this.byCollider.set(collider.handle, rec);
    }
  }
  _spawnPickup(kind, list, tileIndex) {
    const proto = this.pickupProtos.get(kind); if (!proto || !Array.isArray(list)) return;
    if (kind === 'HiddenPackage_PickUp' && hiddenList().indexOf(this.trackKey) >= 0) return;
    const name = kind.replace('_PickUp', '');
    for (const entry of list) {
      const pos = entry[0];
      const mesh = proto.clone(true); mesh.position.set(pos.x, pos.y, pos.z); mesh.name = kind;
      this.scene.add(mesh);
      this.pickups.push({ kind: name, mesh, pos: new THREE.Vector3(pos.x, pos.y, pos.z), tileIndex, alive: true });
    }
  }
  update(carPos, now) {
    for (const p of this.props) { if (!p.alive || p.static) continue;
      p.pp.copy(p.cp); p.pq.copy(p.cq);
      const t = p.body.translation(), r = p.body.rotation(); p.cp.set(t.x, t.y, t.z); p.cq.set(r.x, r.y, r.z, r.w); }
    for (let i = this.schedule.length - 1; i >= 0; i--) { const s = this.schedule[i]; if (now >= s.at) { this.schedule.splice(i, 1); this.damage(s.prop, s.dmg, s.sender); } }
    for (const p of this.pickups) { if (!p.alive) continue;
      if (carPos && p.pos.distanceTo(carPos) < 3.0) { p.alive = false; this.scene.remove(p.mesh); this.onPickup(p); } }
  }
  render(alpha, camPos) {
    for (const p of this.props) { if (!p.alive || p.static) continue;
      p.mesh.position.lerpVectors(p.pp, p.cp, alpha); p.mesh.quaternion.slerpQuaternions(p.pq, p.cq, alpha); }
    for (const p of this.pickups) { if (!p.alive) continue;
      const yA = this._v1.copy(p.pos).sub(camPos).normalize();
      const zA = this._v2.set(0, 0, 1).addScaledVector(yA, -yA.z);
      if (zA.lengthSq() < 1e-8) zA.set(0, 1, 0); else zA.normalize();
      const xA = this._v3.crossVectors(yA, zA);
      this._m.makeBasis(xA, yA, zA); p.mesh.quaternion.setFromRotationMatrix(this._m); }
  }
  damage(prop, dmg, sender) { if (!prop.alive || prop.health === Infinity) return; prop.health -= dmg; if (prop.health <= 0) this.destroy(prop, sender); }
  destroy(prop, sender, silent = false) {
    if (!prop.alive) return;
    prop.alive = false;
    this.byCollider.delete(prop.collider.handle);
    this.world.removeRigidBody(prop.body);
    this.scene.remove(prop.mesh);
    const t = prop.mesh.position;
    if (prop.effect === 'explosion') { this.fx.explosion(t, { duration: 500 }); this.sfx.play('GrenadeExplosion_SFX', { volume: 0.5, throttle: 60 }); this.onAreaDamage({ x: t.x, y: t.y, z: t.z }, [5, 15, 16], sender); }
    if (prop.score > 0) this.onScore(prop.score);
    if (prop.kind === 'GasTank_Object' && this.protos.has('GasTankDestroyed_Object')) {
      const wp = this.protos.get('GasTankDestroyed_Object'); const wreck = wp.clone(true);
      wreck.position.copy(prop.mesh.position); wreck.quaternion.copy(prop.mesh.quaternion); this.scene.add(wreck);
      const body = this.world.createRigidBody(this.RAPIER.RigidBodyDesc.fixed().setTranslation(wreck.position.x, wreck.position.y, wreck.position.z).setRotation({ x: wreck.quaternion.x, y: wreck.quaternion.y, z: wreck.quaternion.z, w: wreck.quaternion.w }));
      const verts = this._geomVerts(wp); const idx = new Uint32Array(verts.length / 3); for (let i = 0; i < idx.length; i++) idx[i] = i;
      const collider = this.world.createCollider(this.RAPIER.ColliderDesc.trimesh(verts, idx).setFriction(0.1).setRestitution(0.1), body);
      const rec = { idx: this.props.length, kind: 'GasTankDestroyed_Object', mesh: wreck, body, collider, tileIndex: prop.tileIndex, alive: true, static: true, mass: 0, health: Infinity, score: 0, type: 'metal', effect: null, pp: wreck.position.clone(), pq: wreck.quaternion.clone(), cp: wreck.position.clone(), cq: wreck.quaternion.clone() };
      this.props.push(rec); this.byCollider.set(collider.handle, rec);
    }
    if (!silent && this.onSync) this.onSync(prop.idx);
  }
  destroyIndex(i) { const p = this.props[i]; if (p && p.alive) this.destroy(p, 'remote', true); }
  detonateTile(tileIndex, sender) {
    const list = this.props.filter(p => p.alive && p.tileIndex === tileIndex);
    const now = performance.now();
    list.forEach((p, i) => this.schedule.push({ at: now + i * 150, prop: p, dmg: 1000, sender }));
  }
}