// postfx.js – DOF + motion blur. The chain works in linear light and the final pass encodes to
// sRGB, so enabling effects no longer darkens the image.
import * as THREE from 'three';
const VS = `varying vec2 vUv; void main(){ vUv = uv; gl_Position = vec4(position.xy, 0.0, 1.0); }`;
const DOF_FS = `
uniform sampler2D tColor, tDepth; uniform float focus, aperture, maxblur, near, far; uniform vec2 resolution;
varying vec2 vUv;
float lin(float d){ float z = 2.0*d - 1.0; return (2.0*near*far)/(far + near - z*(far - near)); }
void main(){
  float d = texture2D(tDepth, vUv).x; float z = lin(d);
  float coc = clamp(abs(z - focus) * aperture, 0.0, maxblur);
  vec2 px = coc / resolution;
  vec3 c = texture2D(tColor, vUv).rgb;
  c += texture2D(tColor, vUv + px*vec2( 0.000, 1.000)).rgb;
  c += texture2D(tColor, vUv + px*vec2( 0.866, 0.500)).rgb;
  c += texture2D(tColor, vUv + px*vec2( 0.866,-0.500)).rgb;
  c += texture2D(tColor, vUv + px*vec2( 0.000,-1.000)).rgb;
  c += texture2D(tColor, vUv + px*vec2(-0.866,-0.500)).rgb;
  c += texture2D(tColor, vUv + px*vec2(-0.866, 0.500)).rgb;
  c += texture2D(tColor, vUv + px*vec2( 0.000, 0.500)).rgb;
  c += texture2D(tColor, vUv + px*vec2( 0.433, 0.250)).rgb;
  c += texture2D(tColor, vUv + px*vec2( 0.433,-0.250)).rgb;
  c += texture2D(tColor, vUv + px*vec2( 0.000,-0.500)).rgb;
  c += texture2D(tColor, vUv + px*vec2(-0.433,-0.250)).rgb;
  c += texture2D(tColor, vUv + px*vec2(-0.433, 0.250)).rgb;
  gl_FragColor = vec4(c / 13.0, 1.0);
}`;
const BLEND_FS = `
uniform sampler2D tCur, tPrev; uniform float damp; varying vec2 vUv;
vec3 srgb(vec3 c){ vec3 lo = 12.92*c; vec3 hi = 1.055*pow(c, vec3(0.41666)) - 0.055; return mix(lo, hi, step(vec3(0.0031308), c)); }
void main(){ vec3 c = mix(texture2D(tCur, vUv).rgb, texture2D(tPrev, vUv).rgb, damp); gl_FragColor = vec4(srgb(c), 1.0); }`;

export class PostFX {
  constructor(renderer) {
    this.renderer = renderer; this.dof = 0; this.motion = 0; this.focus = 30;
    const s = renderer.getSize(new THREE.Vector2()); const pr = renderer.getPixelRatio();
    const w = Math.max(2, s.x * pr), h = Math.max(2, s.y * pr);
    const dt = new THREE.DepthTexture(w, h); dt.type = THREE.UnsignedIntType;
    this.rtScene = new THREE.WebGLRenderTarget(w, h, { depthTexture: dt, depthBuffer: true });
    this.rtA = new THREE.WebGLRenderTarget(w, h);
    this.rtB = new THREE.WebGLRenderTarget(w, h);
    this.quadScene = new THREE.Scene();
    this.quadCam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    this.quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2)); this.quadScene.add(this.quad);
    this.dofMat = new THREE.ShaderMaterial({ uniforms: { tColor: { value: null }, tDepth: { value: null }, focus: { value: 30 }, aperture: { value: 0 }, maxblur: { value: 0.012 }, near: { value: 0.5 }, far: { value: 9000 }, resolution: { value: new THREE.Vector2(w, h) } }, vertexShader: VS, fragmentShader: DOF_FS, depthTest: false, depthWrite: false });
    this.blendMat = new THREE.ShaderMaterial({ uniforms: { tCur: { value: null }, tPrev: { value: null }, damp: { value: 0 } }, vertexShader: VS, fragmentShader: BLEND_FS, depthTest: false, depthWrite: false });
  }
  setSize(w, h, pr) { const W = Math.max(2, w * pr), H = Math.max(2, h * pr);
    this.rtScene.setSize(W, H); this.rtA.setSize(W, H); this.rtB.setSize(W, H);
    this.dofMat.uniforms.resolution.value.set(W, H); }
  render(skyScene, scene, camera) {
    const r = this.renderer;
    if (this.dof <= 0 && this.motion <= 0) { r.setRenderTarget(null); r.clear(); r.render(skyScene, camera); r.clearDepth(); r.render(scene, camera); return; }
    r.setRenderTarget(this.rtScene); r.clear(); r.render(skyScene, camera); r.clearDepth(); r.render(scene, camera);
    const u = this.dofMat.uniforms;
    u.tColor.value = this.rtScene.texture; u.tDepth.value = this.rtScene.depthTexture;
    u.focus.value = this.focus; u.aperture.value = this.dof * 0.0004; u.near.value = camera.near; u.far.value = camera.far;
    this.quad.material = this.dofMat;
    r.setRenderTarget(this.rtA); r.clear(); r.render(this.quadScene, this.quadCam);
    const b = this.blendMat.uniforms;
    b.tCur.value = this.rtA.texture; b.tPrev.value = this.rtB.texture; b.damp.value = this.motion;
    this.quad.material = this.blendMat;
    r.setRenderTarget(null); r.clear(); r.render(this.quadScene, this.quadCam);
    r.setRenderTarget(this.rtB); r.clear(); r.render(this.quadScene, this.quadCam);
    r.setRenderTarget(null);
  }
}