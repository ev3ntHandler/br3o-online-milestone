// race.js – point-to-point race. Finish registers by radius OR by crossing the finish plane,
// so fast cars can't skip it. Exposes finishYaw so the gantry prop faces the travel direction.
import * as THREE from 'three';
const DIRV = { SouthNorth: [0, 1], NorthSouth: [0, -1], WestEast: [1, 0], EastWest: [-1, 0],
  SouthEast: [0.707, 0.707], SouthWest: [-0.707, 0.707], NorthEast: [0.707, -0.707], NorthWest: [-0.707, -0.707],
  EastNorth: [0.707, 0.707], EastSouth: [0.707, -0.707], WestNorth: [-0.707, 0.707], WestSouth: [-0.707, -0.707] };

export class Race {
  constructor({ laps = 1, gateRadius = 45 } = {}) { this.laps = laps; this.gateRadius = gateRadius; this.gates = []; this.finishGate = null; this.finishDir = new THREE.Vector3(0, 1, 0); this.finishYaw = 0; this._prev = null; this.reset(); }
  build(tiles) {
    this.gates = [];
    for (const t of tiles) { if (t.deco) continue;
      const d = DIRV[t.direction] || [0, 1];
      this.gates.push(new THREE.Vector3(t.position.x + d[0] * 125, t.position.y + d[1] * 125, t.position.z)); }
    this.finishGate = this.gates.length ? this.gates[this.gates.length - 1] : null;
    if (this.gates.length > 1) {
      const a = this.gates[this.gates.length - 2];
      this.finishDir = this.finishGate.clone().sub(a); this.finishDir.z = 0;
      if (this.finishDir.lengthSq() < 1e-6) this.finishDir.set(0, 1, 0); else this.finishDir.normalize();
    }
    this.finishYaw = Math.atan2(-this.finishDir.x, this.finishDir.y);
    this.reset();
  }
  reset() { this.next = 0; this.lap = 1; this.started = false; this.finished = false; this.t0 = 0; this.lapT0 = 0; this.lastLap = 0; this.best = 0; this.total = 0; this._prev = null; }
  _finish(now) { this.finished = true; this.total = now - this.t0; this.lastLap = this.total; this.best = this.best ? Math.min(this.best, this.total) : this.total; }
  update(carPos, speed, now) {
    if (this.finished || !this.gates.length || !this.finishGate) { this._prev = carPos.clone(); return; }
    if (!this.started) { if (Math.abs(speed) > 2) { this.started = true; this.t0 = now; this.lapT0 = now; } this._prev = carPos.clone(); return; }
    const g = this.gates[this.next];
    if (carPos.distanceTo(g) < this.gateRadius) this.next = Math.min(this.next + 1, this.gates.length - 1);
    const d = carPos.distanceTo(this.finishGate);
    if (d < 70) { this._finish(now); }
    else if (this._prev) {
      const a = this._prev.clone().sub(this.finishGate).dot(this.finishDir);
      const b = carPos.clone().sub(this.finishGate).dot(this.finishDir);
      if (a < 0 && b >= 0) {
        const lat = carPos.clone().sub(this.finishGate); lat.addScaledVector(this.finishDir, -lat.dot(this.finishDir));
        if (lat.length() < 70) this._finish(now);
      }
    }
    this._prev = carPos.clone();
  }
  hud(now) {
    if (!this.started) return `LAP 1/${this.laps} · ––`;
    const cur = this.finished ? this.total : now - this.t0;
    const fmt = (ms) => (ms / 1000).toFixed(2) + 's';
    return `LAP ${Math.min(this.lap, this.laps)}/${this.laps} · ${fmt(cur)}` + (this.best ? ` · best ${fmt(this.best)}` : '');
  }
}