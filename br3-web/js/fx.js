// fx.js – particles + positional WebAudio (distance-attenuated hits / weapon fire).
import * as THREE from 'three';
const ATLAS = 4, FRAMES = 16, CAP = 384, SPEED = 2.5;
const ZAXIS = new THREE.Vector3(0, 0, 1);
const HIT = {
  wood: ['HitWood1_SFX', 'HitWood2_SFX', 'HitWood3_SFX'],
  metal: ['HitMetal1_SFX', 'HitMetal2_SFX', 'HitMetal3_SFX', 'HitMetal4_SFX', 'HitMetal5_SFX', 'HitMetal6_SFX'],
  concrete: ['HitConcrete1_SFX', 'HitConcrete2_SFX'],
  glass: ['HitGlass1_SFX', 'HitGlass2_SFX', 'HitGlass3_SFX'],
  plastic: ['HitDefault1_SFX', 'HitDefault2_SFX', 'HitDefault3_SFX'],
  none: ['HitDefault1_SFX', 'HitDefault2_SFX', 'HitDefault3_SFX', 'HitDefault4_SFX', 'HitDefault5_SFX', 'HitDefault6_SFX'],
};

export class FX {
  constructor(scene, { loadTexture, texDirs }) {
    this.scene = scene; this.loadTexture = loadTexture; this.texDirs = texDirs;
    this.particles = []; this.emitters = []; this.nFire = 0; this.nSmoke = 0;
    this._m = new THREE.Matrix4(); this._q = new THREE.Quaternion();
    this._qz = new THREE.Quaternion(); this._s = new THREE.Vector3();
    this.fireMesh = null; this.smokeMesh = null;
  }
  async init() {
    const first = async (n) => { for (const d of this.texDirs) { const t = await this.loadTexture(d + n + '.png'); if (t) return t; } return null; };
    const fire = await first('ParticleExplosion1_Texture');
    const smoke = await first('ParticleSmoke1_Texture');
    const mk = (tex, order, blending) => {
      const geo = new THREE.PlaneGeometry(1, 1);
      geo.setAttribute('aUvOffset', new THREE.InstancedBufferAttribute(new Float32Array(CAP * 2), 2));
      const mat = new THREE.MeshBasicMaterial({ map: tex, color: 0xffffff, transparent: true, depthWrite: false, side: THREE.DoubleSide, blending });
      mat.onBeforeCompile = (sh) => { sh.vertexShader = 'attribute vec2 aUvOffset;\n' + sh.vertexShader.replace('#include <uv_vertex>', '#include <uv_vertex>\n#ifdef USE_MAP\n\tvMapUv = vMapUv * 0.25 + aUvOffset;\n#endif'); };
      const mesh = new THREE.InstancedMesh(geo, mat, CAP);
      mesh.count = 0; mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
      mesh.frustumCulled = false; mesh.renderOrder = order; this.scene.add(mesh);
      return mesh;
    };
    this.smokeMesh = mk(smoke, 9, THREE.MultiplyBlending);
    this.fireMesh = mk(fire, 10, THREE.AdditiveBlending);
  }
  _spawn(pos, kind, scale, sizeOverride, lifeOverride) {
    if (kind === 'fire' ? this.nFire >= CAP : this.nSmoke >= CAP) return;
    const p = { kind, pos: new THREE.Vector3(pos.x + (Math.random() * 2 - 1) * 1.5, pos.y + (Math.random() * 2 - 1) * 1.5, pos.z + (Math.random() * 2 - 1) * 1.5 + 0.5),
      life: 0, maxLife: (lifeOverride || (17 + Math.floor(Math.random() * 10))) / SPEED,
      spin: Math.random() * 6.28, spinRate: (Math.random() * 40 - 20) * Math.PI / 180,
      startSize: sizeOverride || (2.4 + Math.random()) * scale };
    if (kind === 'fire') this.nFire++; else this.nSmoke++;
    this.particles.push(p);
  }
  explosion(pos, { duration = 500, scale = 1 } = {}) { this.emitters.push({ pos: new THREE.Vector3(pos.x, pos.y, pos.z), frames: Math.max(1, duration * 32 / 1000 / SPEED), scale, acc: 1 }); }
  spark(pos) { this._spawn(pos, 'fire', 1, 0.5 + Math.random() * 0.4, 5); }
  puff(pos) { this._spawn(pos, 'smoke', 1, 0.5, 12); }
  update(dtFrames, camera) {
    for (let i = this.emitters.length - 1; i >= 0; i--) {
      const e = this.emitters[i]; e.acc += dtFrames;
      while (e.acc >= 1 && e.frames > 0) { e.acc--; e.frames--;
        this._spawn(e.pos, 'fire', e.scale); this._spawn(e.pos, 'fire', e.scale); this._spawn(e.pos, 'fire', e.scale);
        this._spawn(e.pos, 'smoke', e.scale); this._spawn(e.pos, 'smoke', e.scale); }
      if (e.frames <= 0) this.emitters.splice(i, 1);
    }
    let nf = 0, ns = 0;
    const fOff = this.fireMesh.geometry.attributes.aUvOffset, sOff = this.smokeMesh.geometry.attributes.aUvOffset;
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i]; p.life += dtFrames;
      if (p.life >= p.maxLife) { if (p.kind === 'fire') this.nFire--; else this.nSmoke--;
        this.particles[i] = this.particles[this.particles.length - 1]; this.particles.pop(); continue; }
      const k = p.life / p.maxLife, s = p.startSize * (1 + 3 * k);
      p.spin += p.spinRate * dtFrames;
      this._q.copy(camera.quaternion); this._qz.setFromAxisAngle(ZAXIS, p.spin); this._q.multiply(this._qz);
      this._s.set(s, s, s); this._m.compose(p.pos, this._q, this._s);
      const f = Math.min(FRAMES - 1, Math.floor(k * FRAMES)), u = (f % ATLAS) / ATLAS, v = Math.floor(f / ATLAS) / ATLAS;
      if (p.kind === 'fire') { this.fireMesh.setMatrixAt(nf, this._m); fOff.array[nf * 2] = u; fOff.array[nf * 2 + 1] = v; nf++; }
      else { this.smokeMesh.setMatrixAt(ns, this._m); sOff.array[ns * 2] = u; sOff.array[ns * 2 + 1] = v; ns++; }
    }
    this.fireMesh.count = nf; this.smokeMesh.count = ns;
    this.fireMesh.instanceMatrix.needsUpdate = true; fOff.needsUpdate = true;
    this.smokeMesh.instanceMatrix.needsUpdate = true; sOff.needsUpdate = true;
  }
}

export class Sfx {
  constructor(dataDir, enabled = true) {
    this.dir = dataDir + 'Shared/Audio/'; this.enabled = enabled;
    this.ctx = null; this.buffers = new Map(); this.loading = new Map(); this.last = new Map();
    this.voices = new Map(); this.loops = new Map();
  }
  unlock() {
    if (!this.enabled) return;
    if (!this.ctx) {
      try { this.ctx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { this.enabled = false; return; }
      const names = ['MachineGun_SFX', 'MiniGun_SFX', 'RocketPodLaunch_SFX', 'RocketPodExplosion_SFX', 'Mine1_SFX',
        'MineGrenadeExplosion_SFX', 'GrenadeExplosion_SFX', 'GrenadeLauncher1_SFX', 'Grenade1_SFX', 'PickupGeneric',
        'PickupCash', 'PickUpCarRepair', 'NitroStart', 'Explosion_SFX', 'Bump_SFX', 'CarStationair_SFX'];
      for (const k of Object.keys(HIT)) names.push(...HIT[k]);
      for (const n of names) this._load(n);
    }
    if (this.ctx.state === 'suspended') this.ctx.resume();
  }
  setListener(pos, fwd, up) {
    if (!this.ctx) return; const l = this.ctx.listener;
    if (l.positionX) { l.positionX.value = pos.x; l.positionY.value = pos.y; l.positionZ.value = pos.z;
      l.forwardX.value = fwd.x; l.forwardY.value = fwd.y; l.forwardZ.value = fwd.z;
      l.upX.value = up.x; l.upY.value = up.y; l.upZ.value = up.z; }
    else { l.setPosition(pos.x, pos.y, pos.z); l.setOrientation(fwd.x, fwd.y, fwd.z, up.x, up.y, up.z); }
  }
  _load(name) {
    if (this.buffers.has(name) || this.loading.has(name)) return;
    const pr = fetch(this.dir + name + '.wav').then(r => r.ok ? r.arrayBuffer() : Promise.reject(new Error('HTTP ' + r.status)))
      .then(b => this.ctx.decodeAudioData(b)).then(buf => { this.buffers.set(name, buf); this.loading.delete(name); })
      .catch(() => { this.loading.delete(name); });
    this.loading.set(name, pr);
  }
  _voice(name, { volume = 0.6, rate = 1, mono = false } = {}) {
    const buf = this.buffers.get(name); if (!buf) { this._load(name); return null; }
    if (mono) { const p = this.voices.get(name); if (p) { try { p.src.stop(); } catch (e) {} } }
    const src = this.ctx.createBufferSource(); src.buffer = buf; src.playbackRate.value = rate;
    const g = this.ctx.createGain(); g.gain.value = volume; src.connect(g);
    if (mono) this.voices.set(name, { src, g });
    return { src, g };
  }
  play(name, opts = {}) {
    if (!this.enabled || !this.ctx || this.ctx.state !== 'running') return;
    const now = performance.now();
    if (opts.throttle && now - (this.last.get(name) || 0) < opts.throttle) return;
    this.last.set(name, now);
    const v = this._voice(name, opts); if (!v) return;
    v.g.connect(this.ctx.destination); v.src.start();
  }
  playAt(name, pos, opts = {}) {
    if (!this.enabled || !this.ctx || this.ctx.state !== 'running') return;
    const now = performance.now();
    const key = name + '@';
    if (opts.throttle && now - (this.last.get(key) || 0) < opts.throttle) return;
    this.last.set(key, now);
    const v = this._voice(name, opts); if (!v) return;
    const p = this.ctx.createPanner();
    p.panningModel = 'equalpower'; p.distanceModel = 'inverse';
    p.refDistance = 10; p.maxDistance = 300; p.rolloffFactor = 1.4;
    if (p.positionX) { p.positionX.value = pos.x; p.positionY.value = pos.y; p.positionZ.value = pos.z; }
    else p.setPosition(pos.x, pos.y, pos.z);
    v.g.connect(p); p.connect(this.ctx.destination); v.src.start();
  }
  hit(type, pos, volume = 0.5) {
    const list = HIT[type] || HIT.none;
    this.playAt(list[Math.floor(Math.random() * list.length)], pos, { volume, rate: 0.9 + Math.random() * 0.2, throttle: 50 });
  }
  startLoop(name, { volume = 0.4, rate = 1 } = {}) {
    if (!this.enabled || !this.ctx || this.ctx.state !== 'running') return;
    if (this.loops.has(name)) { this.setLoopRate(name, rate); return; }
    const buf = this.buffers.get(name); if (!buf) { this._load(name); return; }
    const src = this.ctx.createBufferSource(); src.buffer = buf; src.loop = true; src.playbackRate.value = rate;
    const g = this.ctx.createGain(); g.gain.value = volume; src.connect(g); g.connect(this.ctx.destination); src.start();
    this.loops.set(name, { src, g });
  }
  setLoopRate(name, rate) { const l = this.loops.get(name); if (l) l.src.playbackRate.value = rate; }
  stopLoop(name) { const l = this.loops.get(name); if (l) { try { l.src.stop(); } catch (e) {} this.loops.delete(name); } }
}