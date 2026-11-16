// Port of "[PS] Advanced Car" hover-car logic. Drive authority is gated on being upright so an
// inverted car cannot drive (the long un-wedge ray reach must not re-enable control upside down).
export const TEMPO = 32;
export const SIM_DT = 0.0333;
export const SUB_STEPS = 4;
export const GRAVITY = -39.24;

const add = (a, b) => [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const mul = (a, s) => [a[0] * s, a[1] * s, a[2] * s];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const len = (a) => Math.hypot(a[0], a[1], a[2]);
const norm = (a) => { const l = len(a) || 1; return [a[0] / l, a[1] / l, a[2] / l]; };

export function rotate(q, v) {
  const [x, y, z, w] = q;
  const tx = 2 * (y * v[2] - z * v[1]);
  const ty = 2 * (z * v[0] - x * v[2]);
  const tz = 2 * (x * v[1] - y * v[0]);
  return [v[0] + w * tx + (y * tz - z * ty), v[1] + w * ty + (z * tx - x * tz), v[2] + w * tz + (x * ty - y * tx)];
}

export class HoverCar {
  constructor({ settings, hoverDist, wheelPoints, phys }) {
    this.s = settings; this.hoverDist = hoverDist; this.wheelPoints = wheelPoints; this.phys = phys;
    this.mass = settings.mass; this.maxSpeed = settings.maxspeed;
    this.accGain = settings.accgain; this.decGain = settings.brakegain; this.turnGain = settings.turngain;
    this.grip = settings.grip; this.drag = settings.drag;
    this.strength = settings.strength; this.damping = settings.damping;
    this.banking = settings.banking; this.maxWheelTurn = settings.maxwheelturn;
    this.speed = 0; this.speedPerc = 0; this.hovering = 0;
    this.isHovering = [0, 0, 0, 0]; this.hoverDists = [0, 0, 0, 0];
    this.slip = 0; this.adjGrip = this.grip;
    this.wheelTurn = 0; this.wheelSpin = 0; this.adjBanking = 0; this.bankAngle = 0;
    this.upright = 1; this.nitro = 0; this.nitroBoost = 45; this.blockedT = 0;
  }
  step(input) {
    const ph = this.phys;
    const q = ph.rotation();
    const fwd = norm(rotate(q, [0, 1, 0]));
    const axis = norm(rotate(q, [0, 0, 1]));
    const right = norm(cross(fwd, axis));
    const down = norm(rotate(q, [0, 0, -1]));
    const pos = ph.position();
    const chassis = add(pos, ph.com());
    const vel = ph.linvel();
    const angVel = ph.angvel();
    this.upright = axis[2];
    this.speed = dot(vel, fwd);
    this.speedPerc = Math.abs(this.speed / this.maxSpeed);
    const uprightOk = this.upright > 0.3;

    const reach = this.hoverDist * 1.7;
    const rayDir = norm([down[0] + 0.0001, down[1] + 0.0001, down[2] + 0.0001]);
    for (let i = 0; i < 4; i++) {
      this.isHovering[i] = 0;
      const wp = add(pos, rotate(q, this.wheelPoints[i]));
      const toi = ph.castRay(wp, rayDir, reach);
      if (toi !== null && toi < reach) {
        this.isHovering[i] = 1;
        this.hoverDists[i] = Math.min(toi, this.hoverDist);
        if (toi < this.hoverDist && uprightOk) {
          const pointVel = add(vel, cross(angVel, sub(wp, chassis)));
          const tdiff = mul(rayDir, toi);
          let tF = -this.strength * (this.hoverDist - toi);
          tF -= this.damping * dot(pointVel, tdiff);
          ph.impulseAt(mul(tdiff, tF * this.mass), wp);
        }
      }
    }
    let powerCoeff = (this.isHovering[0] + this.isHovering[1] + this.isHovering[2] + this.isHovering[3]) / 4;
    if (powerCoeff === 0 && uprightOk) {
      const gtoi = ph.castRay(chassis, [0, 0, -1], this.hoverDist + 1.0);
      if (gtoi !== null) { powerCoeff = 0.8; ph.impulse([0, 0, this.mass * 8]); }
    }
    if (!uprightOk) powerCoeff = 0;              // no driving / un-wedging while inverted
    if (this.isHovering.indexOf(1) < 0) { this.hovering = 0; if (len(angVel) < 0.7) ph.setAngvel(mul(angVel, 0.7)); }
    else this.hovering = 1;

    if (uprightOk && (input.forward || input.backward) && Math.abs(this.speed) < 0.6 && this.hovering === 1) this.blockedT++;
    else this.blockedT = 0;
    if (this.blockedT > 16) { this.blockedT = 0; ph.impulse([0, 0, this.mass * 10]); }

    if (powerCoeff > 0) {
      const adjMax = this.maxSpeed + (this.nitro ? this.nitroBoost : 0);
      let adjTurn = this.turnGain;
      if (Math.abs(this.speed) < this.maxSpeed * 0.225) adjTurn = this.turnGain * Math.min(1, Math.abs(this.speed) / (this.maxSpeed * 0.225));
      if (adjTurn < 0.05) adjTurn = 0;
      let steering = 1;
      if (this.speed < 0 && input.forward) steering = 0;
      else if (this.speed > 0 && input.backward) steering = 0;
      if (input.forward) ph.impulse(mul(fwd, (adjMax - this.speed) * this.accGain * this.mass * powerCoeff));
      if (input.backward) ph.impulse(mul(fwd, ((-adjMax / 2) - this.speed) * this.decGain * this.mass * powerCoeff));
      if (input.brake) { this.slip = 1; this.adjGrip = 0.02; }
      if (this.slip === 1) { if (this.adjGrip < this.grip) this.adjGrip += 0.02; if (this.adjGrip > this.grip) this.adjGrip = this.grip; if (this.adjGrip === this.grip) this.slip = 0; }
      if (steering === 1) {
        if (input.left) { let k = adjTurn * this.mass * 0.9 * powerCoeff; if (this.speed < 0) k = -k; ph.torqueImpulse(mul(axis, k)); }
        if (input.right) { let k = -adjTurn * this.mass * 0.9 * powerCoeff; if (this.speed < 0) k = -k; ph.torqueImpulse(mul(axis, k)); }
      }
      if (len(angVel) > 0) {
        const perc = Math.abs(this.speed) <= this.maxSpeed * 7 ? Math.abs(this.speed) / (this.maxSpeed * 0.7) : 1;
        let comp = 0.25 + adjTurn * perc; if (comp > adjTurn) comp = adjTurn;
        ph.torqueImpulse(mul(axis, dot(angVel, axis) * (-comp * this.mass) * powerCoeff));
      }
      const slide = dot(right, vel);
      ph.impulse(mul(right, -slide * this.mass * this.adjGrip * powerCoeff));
      ph.impulse(mul(vel, -(this.drag * this.mass)));
    }

    if (input.left && !(this.wheelTurn < -0.9)) this.wheelTurn -= 0.1;
    if (input.right && !(this.wheelTurn > 0.9)) this.wheelTurn += 0.1;
    if (!input.left && !input.right && Math.abs(this.wheelTurn) > 1e-6) { this.wheelTurn += this.wheelTurn < 0 ? 0.1 : -0.1; if (Math.abs(this.wheelTurn) < 0.05) this.wheelTurn = 0; }
    this.wheelSpin = (this.wheelSpin - this.speed * 2) % 360;
    if (input.left && !(this.adjBanking < -0.9)) this.adjBanking -= 0.1;
    if (input.right && !(this.adjBanking > 0.9)) this.adjBanking += 0.1;
    if ((!input.left && !input.right) || this.hovering === 0) { if (Math.abs(this.adjBanking) > 1e-6) { this.adjBanking += this.adjBanking < 0 ? 0.1 : -0.1; if (Math.abs(this.adjBanking) < 0.05) this.adjBanking = 0; } }
    this.bankAngle = this.speedPerc * (this.adjBanking * this.banking);

    let reset = false;
    if (this.hovering === 0 && Math.abs(this.speed) <= 0.25 && this.upright < 0.3) reset = true;
    if (this.hovering === 0 && pos[2] <= -35) reset = true;
    return { reset };
  }
}