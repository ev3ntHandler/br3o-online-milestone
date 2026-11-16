// ai.js – waypoint rivals. A waypoint counts as reached when close OR when the car crosses its
// perpendicular beam (waypoint ends up behind the car), so cutting corners still advances.
import * as THREE from 'three';
import { parseLingo, parseEventsFile, plain } from './lingo.js';
import { HoverCar, TEMPO } from './carphysics.js';
const SWITCH = { SouthNorth: 'NorthSouth', NorthSouth: 'SouthNorth', WestEast: 'EastWest', EastWest: 'WestEast', SouthWest: 'WestSouth', WestSouth: 'SouthWest', SouthEast: 'EastSouth', EastSouth: 'SouthEast', WestNorth: 'NorthWest', NorthWest: 'WestNorth', EastNorth: 'NorthEast', NorthEast: 'EastNorth' };
export function buildWaypoints(tiles, world, dataText) {
  const ev = parseEventsFile(dataText); const paths = {};
  for (const c of (ev.blocks[world + 'AIPaths'] || [])) paths[c.cmd] = plain(parseLingo(c.fields[0]));
  const wp = [];
  for (const t of tiles) { if (t.deco) continue;
    let key = t.type + '_' + t.direction, rev = false; let list = paths[key];
    if (!list) { key = t.type + '_' + (SWITCH[t.direction] || t.direction); rev = true; list = paths[key]; }
    if (!list || !list.length) { wp.push(new THREE.Vector3(t.position.x, t.position.y + 125, t.position.z)); continue; }
    const order = list.map((_, i) => i); if (rev) order.reverse();
    for (const i of order) { const p = list[i]; wp.push(new THREE.Vector3(t.position.x + p.x, t.position.y + p.y, t.position.z + p.z)); } }
  return wp;
}
const wrap = (a) => Math.atan2(Math.sin(a), Math.cos(a));
export class AI {
  constructor({ scene, world, RAPIER, loadCar, loadCarData, waypoints, starts, count = 3, getPlayerPos }) {
    Object.assign(this, { scene, world, RAPIER, loadCar, loadCarData, waypoints, starts, getPlayerPos });
    this.count = count; this.cars = []; this._v = new THREE.Vector3();
  }
  _resetToWp(a) {
    const g = this.waypoints[a.wp], nx = this.waypoints[(a.wp + 1) % this.waypoints.length];
    const yaw = Math.atan2(-(nx.x - g.x), (nx.y - g.y)); const h = yaw / 2;
    a.body.setTranslation({ x: g.x, y: g.y, z: g.z + 0.7 }, true);
    a.body.setRotation({ x: 0, y: 0, z: Math.sin(h), w: Math.cos(h) }, true);
    a.body.setLinvel({ x: 0, y: 0, z: 0 }, true); a.body.setAngvel({ x: 0, y: 0, z: 0 }, true);
    a.car.isHovering = [0, 0, 0, 0]; a.stuck = 0;
  }
  async _spawn(rawName, start, idx) {
    const name = String(rawName).replace(/Rival$/i, '');
    const { settings, kit, health } = await this.loadCarData(name);
    const rig = await this.loadCar(name, kit, null);
    const p = start.position || { x: 0, y: 0, z: 0 };
    const body = this.world.createRigidBody(this.RAPIER.RigidBodyDesc.dynamic().setTranslation(p.x, p.y, p.z + 0.7).setRotation({ x: 0, y: 0, z: 0, w: 1 }).setAngularDamping(1.3).setLinearDamping(0.1).setCanSleep(false).setCcdEnabled(true));
    const hull = this.RAPIER.ColliderDesc.convexHull(rig.proxy); if (!hull) return null;
    const collider = this.world.createCollider(hull.setFriction(settings.friction).setRestitution(settings.restitution).setMass(settings.mass), body);
    const c = body.localCom(); const com = [c.x, c.y, c.z];
    const hw = rig.width * 0.5, wb = rig.wheelBase;
    const wheelPoints = [[com[0] - hw, com[1] + wb, com[2]], [com[0] + hw, com[1] + wb, com[2]], [com[0] - hw, com[1] - wb, com[2]], [com[0] + hw, com[1] - wb, com[2]]];
    const V = (a) => ({ x: a[0], y: a[1], z: a[2] });
    const phys = { position: () => { const t = body.translation(); return [t.x, t.y, t.z]; }, rotation: () => { const r = body.rotation(); return [r.x, r.y, r.z, r.w]; },
      linvel: () => { const v = body.linvel(); return [v.x, v.y, v.z]; }, angvel: () => { const v = body.angvel(); return [v.x, v.y, v.z]; }, com: () => com,
      castRay: (o, d, m) => { const h = this.world.castRay(new this.RAPIER.Ray(V(o), V(d)), m, true, undefined, undefined, undefined, body); return h ? (h.timeOfImpact !== undefined ? h.timeOfImpact : h.toi) : null; },
      impulse: (v) => body.applyImpulse(V(v), true), impulseAt: (v, pt) => body.applyImpulseAtPoint(V(v), V(pt), true), torqueImpulse: (v) => body.applyTorqueImpulse(V(v), true), setAngvel: (v) => body.setAngvel(V(v), true) };
    const car = new HoverCar({ settings, hoverDist: rig.hoverZ0 + settings.hoveroffset, wheelPoints, phys });
    this.scene.add(rig.root); rig.root.position.set(p.x, p.y, p.z + 0.7);
    const sv = new THREE.Vector3(p.x, p.y, p.z);
    let best = 0, bd = Infinity;
    for (let i = 0; i < this.waypoints.length; i++) { const d = this.waypoints[i].distanceToSquared(sv); if (d < bd) { bd = d; best = i; } }
    const q0 = new THREE.Quaternion(0, 0, 0, 1);
    return { tag: 'AI' + idx, name, rig, body, car, phys, collider, wp: best, stuck: 0, lapCount: 0, health, maxHealth: health, dead: false, respawnAt: 0, visuals: null, weapons: null, pp: sv.clone(), pq: q0.clone(), cp: sv.clone(), cq: q0.clone() };
  }
  async init() {
    const n = Math.min(this.count, this.starts.length);
    for (let i = 0; i < n; i++) { const s = this.starts[i]; const name = s.car || s.name || 'BMW';
      let rec = null;
      try { rec = await this._spawn(name, s, i); } catch (e) { try { rec = await this._spawn('BMW', s, i); } catch (e2) { console.warn('AI skipped', name, e2); } }
      if (rec) this.cars.push(rec); }
  }
  progress(a) { return a.lapCount * this.waypoints.length + a.wp; }
  update(now) {
    if (!this.waypoints.length) return;
    const pp = this.getPlayerPos ? this.getPlayerPos() : null;
    for (const a of this.cars) {
      if (a.dead) { if (now >= a.respawnAt) { a.dead = false; a.health = a.maxHealth;
          if (a.visuals) { a.visuals.cleanup(); a.visuals.setDamage(0); }
          if (a.weapons) a.weapons.cleanup();
          a.rig.root.visible = true; this._resetToWp(a);
        } else continue; }
      a.pp.copy(a.cp); a.pq.copy(a.cq);
      const t = a.body.translation(); const pos = this._v.set(t.x, t.y, t.z);
      const r = a.body.rotation();
      const f = new THREE.Vector3(0, 1, 0).applyQuaternion(new THREE.Quaternion(r.x, r.y, r.z, r.w));
      const to = this.waypoints[a.wp].clone().sub(pos);
      // reached if close, or crossed the waypoint's perpendicular beam (now behind us)
      if (to.length() < 22 || to.dot(f) < 0) { a.wp++; if (a.wp >= this.waypoints.length) { a.wp = 0; a.lapCount++; } }
      const to2 = this.waypoints[a.wp].clone().sub(pos);
      const desiredYaw = Math.atan2(-to2.x, to2.y);
      const err = wrap(desiredYaw - Math.atan2(-f.x, f.y));
      let action1 = 0, action2 = 0;
      if (pp) { const d = pp.clone().sub(pos); const dist = d.length();
        if (dist < 160 && dist > 8) { const dn = d.clone().normalize(); const ahead = dn.dot(f);
          const side = Math.abs(dn.dot(new THREE.Vector3(1, 0, 0).applyQuaternion(new THREE.Quaternion(r.x, r.y, r.z, r.w))));
          if (ahead > 0.9 && side < 0.25) action1 = 1;
          if (ahead > 0.8 && dist < 110 && Math.random() < 0.02) action2 = 1; } }
      const inp = { forward: 1, backward: 0, left: err > 0.06 ? 1 : 0, right: err < -0.06 ? 1 : 0, brake: Math.abs(err) > 0.7 ? 1 : 0, action1, action2 };
      a.car.step(inp);
      if (a.weapons) a.weapons.update(inp);
      if (Math.abs(a.car.speed) < 0.5 || a.car.upright < 0.3) a.stuck += 1 / TEMPO; else a.stuck = 0;
      if (a.stuck > 1.5) this._resetToWp(a);
      const tr = a.body.translation(), ro = a.body.rotation();
      a.cp.set(tr.x, tr.y, tr.z); a.cq.set(ro.x, ro.y, ro.z, ro.w);
    }
  }
  render(alpha) {
    for (const a of this.cars) { if (a.dead) continue;
      a.rig.root.position.lerpVectors(a.pp, a.cp, alpha);
      a.rig.root.quaternion.slerpQuaternions(a.pq, a.cq, alpha);
      if (a.rig.hideWheels) continue;
      for (let i = 0; i < 4; i++) { const w = a.rig.wheels[i], wp = a.car.wheelPoints[i];
        const L = a.car.isHovering[i] ? a.car.hoverDists[i] : a.car.hoverDist;
        w.position.set(wp[0], wp[1] + a.rig.radiusDEV, wp[2] - L + a.rig.radius);
        const right = i === 1 || i === 3;
        w.rotation.set(THREE.MathUtils.degToRad(right ? -a.car.wheelSpin : a.car.wheelSpin), 0, right ? Math.PI : 0); } }
  }
}