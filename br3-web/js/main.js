// Burnin' Rubber 3 – browser port. Multiplayer sync, black translucent nametags with long-range
// fade, remote wreck debris parity, networked bullet-impact sparks, persistent mines.
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { parseLingo, parseEventsFile, plain } from './lingo.js';
import { HoverCar, TEMPO, SIM_DT, SUB_STEPS, GRAVITY, rotate } from './carphysics.js';
import { FX, Sfx } from './fx.js';
import { PostFX } from './postfx.js';
import { Props, loadSharedData } from './props.js';
import { Weapons } from './weapons.js';
import { Race } from './race.js';
import { AI, buildWaypoints } from './ai.js';
import { Net } from './net.js';
import { loadCareer, saveCareer, addCash, unlock, isUnlocked, AVAILABLE_CARS } from './career.js';

THREE.Object3D.DEFAULT_UP.set(0, 0, 1);
const params = new URLSearchParams(location.search);
const TRACK = params.get('track') || 'CityTrack1';
const CAR = params.get('car') || 'BMW';
const LIGHTMAPS = params.get('lightmaps') !== '0';
const LM_GAIN = parseFloat(params.get('lm') || '1');
const DATA = (params.get('data') || '../Data/').replace(/\/?$/, '/');
const CONVERTED = './converted/';
const USE_PHYSICS = params.get('physics') !== '0';
const START_FLY = params.get('fly') === '1';
const LINEAR_DAMPING = parseFloat(params.get('ld') || '0.1');
const OBSTACLE_FRICTION = 0.5, OBSTACLE_RESTITUTION = 0.4;
const PRIMARY = params.get('primary') || 'MachineGun';
const SECONDARY = params.get('secondary') || 'RocketPod';
const USE_WEAPONS = params.get('weapons') !== '0';
const USE_PROPS = params.get('props') !== '0';
const USE_PICKUPS = params.get('pickups') !== '0';
const SOUND = params.get('sound') !== '0';
const AI_COUNT = parseInt(params.get('ai') || '3', 10);
const AUTOSTART = params.get('autostart') === '1' || params.get('menu') === '0';
const ROOM = params.get('room') || null;
const WS = params.get('ws') || null;
const PLAYER_NAME = params.get('name') || null;
const DEBUG_CASH = 99999999;
const WRECK_HOLD = 2200;                    // ms the wreck stays visible before hiding
const TAG_FADE_NEAR = 160, TAG_FADE_FAR = 750;
const SKIN_WHEEL_CARS = ['BlackTruck', 'DodgeRam', 'MiniCooper', 'Marcos'];
const SHARED_FIRST = new Set(['Misc_Texture', 'Advertisements_Texture', 'Arrows_Texture', 'Crosses_Texture', 'Effects_Texture', 'Debris_Texture', 'CarDamage1_Texture', 'CarDamage2_Texture', 'CarReflection_Texture', 'PickUps_Texture', 'Weapons_Texture', 'Nitro_Texture', 'RocketTrail_Texture', 'ParticleExplosion1_Texture', 'ParticleSmoke1_Texture', 'Interface_Texture', 'Skybox_Texture', 'Finish_Texture', 'SimpleShadow_Texture']);
const VEG_PROBES = ['Cactus_Texture', 'DesertCactus_Texture', 'Plants_Texture', 'DesertPlants_Texture', 'JunglePlants_Texture', 'Tree_Texture', 'Trees_Texture', 'JungleTree_Texture', 'Wood_Texture', 'TreeWood_Texture', 'Trunk_Texture', 'JungleWood_Texture', 'Palm_Texture', 'Banana_Texture', 'Leaf_Texture'];
const EMOTES = [
  { e: '😄', s: 'PickupGeneric' }, { e: '😂', s: 'BaboonHit_SFX' }, { e: '😡', s: 'PigHit_SFX' }, { e: '😎', s: 'NitroStart' },
  { e: '😭', s: 'HitGlass1_SFX' }, { e: '😱', s: 'HitMetal1_SFX' }, { e: '😍', s: 'PickupCash' }, { e: '🤪', s: 'Grenade1_SFX' },
];
const TRACKS = [];
for (let i = 1; i <= 17; i++) TRACKS.push(['CityTrack' + i, 'City ' + i]);
for (let i = 1; i <= 13; i++) TRACKS.push(['DesertTrack' + i, 'Desert ' + i]);
for (let i = 101; i <= 108; i++) TRACKS.push(['DesertTrack' + i, 'Desert ' + i]);
for (let i = 1; i <= 12; i++) TRACKS.push(['JungleTrack' + i, 'Jungle ' + i]);
for (let i = 1; i <= 12; i++) TRACKS.push(['SnowTrack' + i, 'Snow ' + i]);
let RAPIER = null;

const career = loadCareer();
career.cash = DEBUG_CASH;
career.car = CAR; career.primaryWeapon = PRIMARY; career.secondaryWeapon = SECONDARY;
if (PLAYER_NAME) career.playerName = PLAYER_NAME;
if (!career.playerName) career.playerName = 'Player';
saveCareer(career);
const $ = (id) => document.getElementById(id);
const $status = $('status'), $popup = $('popup'), $menu = $('menu'), $results = $('results'), $cd = $('countdown'), $fc = $('freecam'), $wheel = $('emoteWheel');
const say = (s) => { $status.textContent = s; };
function fail(e) { console.error(e); const el = $('error'); el.style.display = 'flex'; el.textContent = String(e && e.message ? e.message : e) + '\n\nServe over http; run tools/convert_all.py; check ?data=.'; }

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = THREE.NoToneMapping;
document.body.prepend(renderer.domElement);
const scene = new THREE.Scene(); const skyScene = new THREE.Scene();
renderer.autoClear = false; renderer.info.autoReset = false;
const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.5, 9000);
const postfx = new PostFX(renderer);
window.addEventListener('resize', () => { camera.aspect = window.innerWidth / window.innerHeight; camera.updateProjectionMatrix(); renderer.setSize(window.innerWidth, window.innerHeight); postfx.setSize(window.innerWidth, window.innerHeight, renderer.getPixelRatio()); });

async function fetchText(u) { const r = await fetch(u); if (!r.ok) throw new Error(`Could not load ${u} (HTTP ${r.status})`); return r.text(); }
const texCache = new Map();
function loadTexture(url, { channel = 0 } = {}) { const k = url + '#' + channel;
  if (!texCache.has(k)) texCache.set(k, new Promise(res => { new THREE.TextureLoader().load(url, t => { t.flipY = false; t.colorSpace = THREE.SRGBColorSpace; t.wrapS = t.wrapT = THREE.RepeatWrapping; t.anisotropy = renderer.capabilities.getMaxAnisotropy(); t.channel = channel; res(t); }, undefined, () => res(null)); }));
  return texCache.get(k); }
async function firstTexture(n, dirs, o) { for (const d of dirs) { const t = await loadTexture(`${d}${n}.png`, o); if (t) return t; } return null; }
const gltfLoader = new GLTFLoader();
const glbCache = new Map();
const loadGLB = (n) => { if (!glbCache.has(n)) glbCache.set(n, gltfLoader.loadAsync(CONVERTED + n + '.glb')); return glbCache.get(n); };
const baseColor = (m) => m.color ? m.color.clone() : new THREE.Color(1, 1, 1);
const rand = (a, b) => a + Math.random() * (b - a);
function uvRect(o) { const uv = o.geometry.attributes.uv; let u0 = 1, v0 = 1, u1 = 0, v1 = 0;
  for (let i = 0; i < uv.count; i++) { u0 = Math.min(u0, uv.getX(i)); u1 = Math.max(u1, uv.getX(i)); v0 = Math.min(v0, uv.getY(i)); v1 = Math.max(v1, uv.getY(i)); }
  return { u0, v0, u1, v1 }; }

async function makeMaterial(src, texDirs, mn) {
  const name = src.name || '';
  if (/Collision/i.test(name)) return null;
  const wantAlpha = /Transparent|Waves|Skybox_Material|RearLight|FrontLight|Finish/i.test(name);
  const texName = src.userData && src.userData.texture;
  const dirs = (texName && SHARED_FIRST.has(texName)) ? [texDirs[1], texDirs[0]] : texDirs;
  let map = texName ? await firstTexture(texName, dirs) : null;
  const tag = (mn || '') + ' ' + name;
  const isTrunk = /trunk|wood|bark/i.test(tag);
  const isVeg = isTrunk || /cactus|plant|bush|palm|banana|leaf|leaves|foliage|tree/i.test(tag);
  if (!map && isVeg) for (const c of VEG_PROBES) { map = await firstTexture(c, dirs); if (map) break; }
  let color = map ? new THREE.Color(0xffffff) : baseColor(src);
  if (!map) { if (isTrunk) color = new THREE.Color(0x6b4a2b); else if (isVeg) color = new THREE.Color(0x3f7a34); else if (color.r > 0.9 && color.g > 0.9 && color.b > 0.9) color = new THREE.Color(0x9a9a9a); }
  const m = new THREE.MeshBasicMaterial({ map, color, side: THREE.DoubleSide, transparent: wantAlpha, alphaTest: wantAlpha ? 0.02 : 0, depthWrite: !wantAlpha });
  m.name = name; return m;
}

async function loadTrack() {
  const mt = /^([A-Za-z]+?)Track(\d+)$/.exec(TRACK);
  if (!mt) throw new Error(`Track "${TRACK}" should look like CityTrack1`);
  const world = mt[1], trackDir = `${DATA}Tracks/${world}/`;
  say(`Reading ${TRACK}…`);
  const ev = parseEventsFile(await fetchText(`${trackDir}Data/${TRACK}Events.txt`));
  const db = ev.blocks[`${TRACK}Data`] || [];
  const get = (c) => { const x = db.find(y => y.cmd === c); return x ? x.fields[0] : undefined; };
  const trackInfo = { name: get('Name') || TRACK, fog: String(get('Fog')).toUpperCase() === 'TRUE',
    fogColor: get('FogColor') ? plain(parseLingo(get('FogColor'))) : [156, 153, 116],
    fogRange: get('FogRange') ? plain(parseLingo(get('FogRange'))) : [25, 600],
    skybox: get('Skybox'), targetTime: get('TargetTime') ? Number(plain(parseLingo(get('TargetTime')))) : 0,
    player: get('PlayerCar') ? plain(parseLingo(get('PlayerCar'))) : null,
    ai: db.filter(c => c.cmd === 'AICar').map(c => plain(parseLingo(c.fields[0]))) };
  const tiles = (ev.blocks[`${TRACK}Build`] || []).filter(c => c.cmd === 'CreateTile').map(c => ({ asset: c.fields[0], ...plain(parseLingo(c.fields[1])) }));
  const [r, g, b] = trackInfo.fogColor;
  const fogCol = new THREE.Color().setRGB(r / 255, g / 255, b / 255, THREE.SRGBColorSpace);
  skyScene.background = fogCol;
  if (trackInfo.fog) scene.fog = new THREE.Fog(fogCol, trackInfo.fogRange[0], trackInfo.fogRange[1]);
  const assetNames = [...new Set(tiles.map(t => t.asset))];
  const texDirs = [`${trackDir}Textures/`, `${DATA}Shared/Textures/`];
  const protos = new Map(), missing = new Set(), tileInstances = []; let n = 0;
  for (const asset of assetNames) {
    say(`Loading ${asset}.glb…`);
    const gltf = await loadGLB(asset);
    const matCache = new Map();
    const getMat = async (src, mn) => { const k = src.name + '|' + (mn || ''); if (!matCache.has(k)) matCache.set(k, makeMaterial(src, texDirs, mn)); return matCache.get(k); };
    for (const t of tiles.filter(t => t.asset === asset)) {
      if (!protos.has(t.type)) {
        const root = gltf.scene.getObjectByName(`${t.type}_Root`);
        if (!root) { missing.add(t.type); protos.set(t.type, null); }
        else { const proto = root.clone(true); const jobs = [];
          proto.traverse(o => { if (!o.isMesh) return; o.frustumCulled = true;
            jobs.push((async () => { let m = await getMat(o.material, o.name);
              if (!m) { o.visible = false; o.userData.collision = true; return; }
              if (LIGHTMAPS && /Street$/.test(o.name) && o.geometry.attributes.uv1) { const lm = await loadTexture(`${trackDir}Textures/${t.type}StreetLightmap_Texture.png`, { channel: 1 }); if (lm) { m = m.clone(); m.lightMap = lm; m.lightMapIntensity = Math.PI * LM_GAIN; } }
              o.material = m; })()); });
          await Promise.all(jobs); protos.set(t.type, proto); }
      }
      const proto = protos.get(t.type); if (!proto) continue;
      const inst = proto.clone(true);
      inst.position.set(t.position.x, t.position.y, t.position.z);
      inst.name = `${t.deco ? 'Deco' : 'Track'}Tile_${++n}_${t.type}`;
      scene.add(inst); tileInstances.push({ inst, tile: t });
    }
  }
  if (missing.size) console.warn('missing tiles', [...missing]);
  return { world, trackInfo, tiles, tileCount: n, missing: [...missing], tileInstances };
}

async function loadSky(name) {
  if (!name) return null;
  const gltf = await loadGLB('Skyboxes');
  const sky = new THREE.Group(); const texDirs = [`${DATA}Shared/Textures/`]; const prefix = 'Skybox' + name; const parts = [];
  gltf.scene.traverse(o => { if (o.name.startsWith(prefix) && !o.name.endsWith('_Dummy') && o.isMesh) parts.push(o); });
  let grad = null;
  for (const o of parts) { const r = uvRect(o); const w = r.u1 - r.u0, h = r.v1 - r.v0; if (w < 0.12 && h > 0.2) { grad = r; break; } }
  if (grad) { const tex = await firstTexture('Skybox_Texture', texDirs);
    if (tex && tex.image) { const img = tex.image; const cv = document.createElement('canvas'); cv.width = 8; cv.height = 256;
      const cx = cv.getContext('2d');
      const sx = grad.u0 * img.width, sw = Math.max(1, (grad.u1 - grad.u0) * img.width);
      const sy = (1 - grad.v1) * img.height, sh = Math.max(1, (grad.v1 - grad.v0) * img.height);
      cx.drawImage(img, sx, sy, sw, sh, 0, 0, 8, 256);
      const bt = new THREE.CanvasTexture(cv); bt.colorSpace = THREE.SRGBColorSpace; bt.magFilter = THREE.LinearFilter; bt.minFilter = THREE.LinearFilter;
      skyScene.background = bt; } }
  for (const o of parts) { const c = o.clone(true); const src = o.material;
    const map = src.userData && src.userData.texture ? await firstTexture(src.userData.texture, texDirs) : null;
    const opaque = /Opaque$/.test(o.name);
    c.material = new THREE.MeshBasicMaterial({ map, color: map ? 0xffffff : baseColor(src), side: THREE.DoubleSide, fog: false, transparent: !opaque, alphaTest: opaque ? 0 : 0.02, depthWrite: false, depthTest: false });
    c.renderOrder = opaque ? -30 : /Skyline|Sea/.test(o.name) ? -20 : -10; c.frustumCulled = false; sky.add(c); }
  skyScene.add(sky); return sky;
}

const lowerKeys = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k.toLowerCase(), v]));
async function loadCarData(cn) {
  const ev = parseEventsFile(await fetchText(`${DATA}Cars/CarsData.txt`));
  const entry = (b, n) => { const c = (ev.blocks[b] || []).find(x => x.cmd === n); return c ? lowerKeys(plain(parseLingo(c.fields[0]))) : null; };
  return { settings: entry('CarSettings', cn) || entry('CarSettings', 'Default'),
    kit: entry('BodyKit', 'Player' + cn) || entry('BodyKit', cn) || entry('BodyKit', 'Default'),
    upgrades: entry('Upgrades', cn) || entry('Upgrades', 'Default') || {},
    health: Number((entry('Personality', 'Default') || {}).health) || 200 };
}
function forEachMesh(o, fn) { o.traverse(x => { if (x.isMesh) fn(x); }); }
async function loadCar(cn, kit, skinOverride, targetScene) {
  const gltf = await loadGLB(cn);
  const srcScene = gltf.scene.clone(true);
  const byLower = new Map(); srcScene.traverse(o => { if (o.name) byLower.set(o.name.toLowerCase(), o); });
  const get = (s) => byLower.get((cn + s).toLowerCase());
  const skinDir = `${DATA}Cars/SkinTextures/`;
  const skin = skinOverride || String(kit.skin || 1);
  const skinTex = await loadTexture(`${skinDir}${cn}Skin${skin}_Texture.png`);
  const wheelsTex = await loadTexture(`${skinDir}Wheels_Texture.png`);
  const tireTex = SKIN_WHEEL_CARS.includes(cn) ? skinTex : wheelsTex;
  const basic = (map, o) => new THREE.MeshBasicMaterial({ map, color: map ? 0xffffff : baseColor(o), side: THREE.DoubleSide });
  const wheelNodes = ['Wheel_LF', 'Wheel_RF', 'Wheel_LB', 'Wheel_RB'].map(n => get(n));
  if (wheelNodes.some(w => !w)) throw new Error(`${cn}.glb missing wheels`);
  const rest = wheelNodes.map(w => w.position.clone());
  const width = Math.abs(rest[0].x) + Math.abs(rest[1].x);
  const wheelBase = (Math.abs(rest[1].y) + Math.abs(rest[3].y)) / 2;
  const radiusDEV = Math.abs(rest[0].y - wheelBase);
  const hoverZ0 = get('').position.z;
  const bodyPos = get('').position.clone();
  const restLocal = rest.map(r => r.clone().sub(bodyPos));
  const dummies = new Map(); srcScene.traverse(o => { if (o.name && /_Dummy$/.test(o.name)) dummies.set(o.name, o.position.clone()); });
  let proxy = null; forEachMesh(get('Proxy'), m => { proxy = m.geometry.attributes.position.array.slice(); });
  const root = new THREE.Group(); root.name = 'Car_' + cn;
  const body = new THREE.Group(); body.name = 'CarBody'; root.add(body);
  const lights = { rear: [], front: [] };
  const parts = ['', 'Glass', 'RearLights', 'FrontLights'];
  for (const [k, v] of Object.entries(kit)) if (k !== 'skin' && k !== 'rims' && v > 0) parts.push(k + v);
  for (const p of parts) { const o = get(p); if (!o) continue;
    o.removeFromParent(); o.position.set(0, 0, 0); o.quaternion.identity(); body.add(o);
    forEachMesh(o, m => { const name = m.material.name || '';
      if (/^(Rear|Front)Light_Material$/.test(name)) {
        loadTexture(`${skinDir}${name.replace('_Material', '_Texture')}.png`).then(t => { m.material.map = t; m.material.needsUpdate = true; });
        m.material = new THREE.MeshBasicMaterial({ color: 0xffffff, side: THREE.DoubleSide, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false });
        m.renderOrder = 3; m.visible = false; (/^Rear/.test(name) ? lights.rear : lights.front).push(m);
      } else m.material = basic(skinTex, m.material); }); }
  const rimsNode = kit.rims > 0 ? get('Rims' + kit.rims) : null;
  const tireMat = basic(tireTex, { color: new THREE.Color(1, 1, 1) });
  const rimMat = basic(wheelsTex, { color: new THREE.Color(1, 1, 1) });
  let radius = 0.4;
  for (let i = 0; i < wheelNodes.length; i++) {
    const w = wheelNodes[i]; w.removeFromParent(); root.add(w);
    w.position.copy(restLocal[i]);
    forEachMesh(w, m => { m.material = tireMat; m.geometry.computeBoundingSphere(); radius = m.geometry.boundingSphere.radius; });
    if (rimsNode) { const rc = rimsNode.clone(true); rc.position.set(0, 0, 0); rc.quaternion.identity();
      const right = i === 1 || i === 3; rc.scale.x = right ? -1 : 1;
      forEachMesh(rc, m => { m.material = rimMat; }); w.add(rc); }
  }
  const hideWheels = cn === 'Apache' || cn === 'Tank';
  if (hideWheels) wheelNodes.forEach(w => { w.visible = false; });
  (targetScene || scene).add(root);
  return { root, body, wheels: wheelNodes, rest, restLocal, width, wheelBase, radiusDEV, radius, hoverZ0, proxy, lights, dummies, bodyPos, hideWheels };
}

let damageTex = null, reflectionTex = null, shadowScales = {};
async function loadCarVisualAssets() {
  const dirs = [`${DATA}Shared/Textures/`, `${DATA}Cars/SkinTextures/`];
  const clear = new THREE.DataTexture(new Uint8Array([0, 0, 0, 0]), 1, 1); clear.needsUpdate = true;
  const d1 = await firstTexture('CarDamage1_Texture', dirs);
  const d2 = await firstTexture('CarDamage2_Texture', dirs);
  const db = await firstTexture('Debris_Texture', dirs);
  damageTex = [clear, d1 || clear, d2 || clear, db || clear];
  reflectionTex = await firstTexture('CarReflection_Texture', dirs);
  if (reflectionTex) reflectionTex.mapping = THREE.EquirectangularReflectionMapping;
  try { const g = await fetchText(`${DATA}Globals.txt`);
    for (const line of g.split('\n')) { const t = line.trim(); if (t.startsWith('ShadowScale')) { shadowScales = plain(parseLingo(t.split('\t')[1])) || {}; break; } } } catch (e) {}
}
const _sq = new THREE.Quaternion(), _sy = new THREE.Quaternion(), ZUP = new THREE.Vector3(0, 0, 1);
function setupCarVisuals(rig, cn, getBody) {
  const bodyUniform = { value: damageTex[0] };
  const wheelUniform = { value: damageTex[0] };
  const wrapWith = (uniform) => (m) => { const mm = m.clone();
    mm.onBeforeCompile = (sh) => { sh.uniforms.uDamage = uniform;
      sh.fragmentShader = 'uniform sampler2D uDamage;\n' + sh.fragmentShader.replace('#include <map_fragment>', '#include <map_fragment>\n\tvec4 dmg = texture2D(uDamage, vMapUv);\n\tdiffuseColor.rgb = mix(diffuseColor.rgb, dmg.rgb, dmg.a);'); };
    if (reflectionTex) { mm.envMap = reflectionTex; mm.reflectivity = 0.35; mm.combine = THREE.MixOperation; }
    return mm; };
  const wrapBody = wrapWith(bodyUniform), wrapWheel = wrapWith(wheelUniform);
  rig.body.traverse(o => { if (o.isMesh && !/Light/i.test(o.name) && !/Light/i.test(o.material.name || '')) o.material = wrapBody(o.material); });
  for (const w of rig.wheels) w.traverse(o => { if (o.isMesh) o.material = wrapWheel(o.material); });
  const s = Number(shadowScales[cn]) || 10;
  const shadow = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.35, depthWrite: false }));
  shadow.scale.set(s, s, 1); shadow.renderOrder = 1; scene.add(shadow);
  firstTexture(`${cn}Shadow_Texture`, [`${DATA}Cars/ShadowTextures/`]).then(t => { if (t) { shadow.material.map = t; shadow.material.color = new THREE.Color(0xffffff); shadow.material.opacity = 1; shadow.material.needsUpdate = true; } });
  const glass = []; rig.body.traverse(o => { if (o.isMesh && /Glass/i.test(o.name)) glass.push(o); });
  const debris = [];
  return { shadow, debris,
    setDamage(st) { bodyUniform.value = damageTex[Math.max(0, Math.min(3, st))]; wheelUniform.value = st === 3 ? damageTex[3] : damageTex[0]; },
    detach() { const vel = getBody().linvel(); shadow.visible = false;
      const add = (o) => { const c = o.clone(true); o.getWorldPosition(c.position); o.getWorldQuaternion(c.quaternion); scene.add(c);
        const b = world.createRigidBody(RAPIER.RigidBodyDesc.dynamic().setTranslation(c.position.x, c.position.y, c.position.z).setRotation({ x: c.quaternion.x, y: c.quaternion.y, z: c.quaternion.z, w: c.quaternion.w }).setCcdEnabled(true));
        world.createCollider(RAPIER.ColliderDesc.ball(0.4).setMass(20).setRestitution(0.3).setFriction(0.6), b);
        b.setLinvel({ x: vel.x * 0.7 + rand(-4, 4), y: vel.y * 0.7 + rand(-4, 4), z: rand(4, 9) }, true);
        b.setAngvel({ x: rand(-6, 6), y: rand(-6, 6), z: rand(-6, 6) }, true);
        debris.push({ mesh: c, body: b }); };
      for (const w of rig.wheels) w.traverse(o => { if (o.isMesh) add(o); });
      for (const g of glass) add(g);
      rig.wheels.forEach(w => { w.visible = false; }); glass.forEach(g => { g.visible = false; }); },
    cleanup() { for (const d of debris) { scene.remove(d.mesh); world.removeRigidBody(d.body); } debris.length = 0;
      shadow.visible = true; rig.wheels.forEach(w => { w.visible = !rig.hideWheels; }); glass.forEach(g => { g.visible = true; }); },
    updateDebris() { for (const d of debris) { const t = d.body.translation(), r = d.body.rotation(); d.mesh.position.set(t.x, t.y, t.z); d.mesh.quaternion.set(r.x, r.y, r.z, r.w); } },
    updateShadow(pos, yaw, exclude) {
      let gz = pos.z - rig.hoverZ0 - 0.25, nrm = null;
      if (world && RAPIER) { const h = world.castRayAndGetNormal(new RAPIER.Ray({ x: pos.x, y: pos.y, z: pos.z }, { x: 0, y: 0, z: -1 }), 60, true, undefined, undefined, undefined, exclude);
        if (h) { gz = pos.z - (h.timeOfImpact !== undefined ? h.timeOfImpact : h.toi); nrm = h.normal; } }
      shadow.position.set(pos.x, pos.y, gz + 0.12);
      if (nrm) { const n = new THREE.Vector3(nrm.x, nrm.y, nrm.z).normalize(); _sq.setFromUnitVectors(ZUP, n); _sy.setFromAxisAngle(ZUP, yaw); shadow.quaternion.copy(_sq).multiply(_sy); }
      else shadow.rotation.set(0, 0, yaw); } };
}

// ---- billboard nametags: black translucent plate, long-distance fade ----
function makeNametag(text, accent) {
  const cv = document.createElement('canvas'); cv.width = 512; cv.height = 128;
  const cx = cv.getContext('2d');
  const label = String(text || 'PLAYER').toUpperCase().slice(0, 14);
  cx.font = 'bold 60px system-ui, sans-serif';
  const w = Math.min(486, cx.measureText(label).width + 60);
  const x = (512 - w) / 2, y = 28, h = 74, r = 18;
  cx.fillStyle = 'rgba(0,0,0,0.55)';
  cx.beginPath();
  cx.moveTo(x + r, y); cx.lineTo(x + w - r, y); cx.quadraticCurveTo(x + w, y, x + w, y + r);
  cx.lineTo(x + w, y + h - r); cx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  cx.lineTo(x + r, y + h); cx.quadraticCurveTo(x, y + h, x, y + h - r);
  cx.lineTo(x, y + r); cx.quadraticCurveTo(x, y, x + r, y); cx.closePath(); cx.fill();
  cx.fillStyle = accent || '#ffd34d';
  cx.fillRect(x + 14, y + h - 8, w - 28, 4);
  cx.fillStyle = '#ffffff'; cx.textAlign = 'center'; cx.textBaseline = 'middle';
  cx.fillText(label, 256, y + h / 2 - 3);
  const tex = new THREE.CanvasTexture(cv); tex.colorSpace = THREE.SRGBColorSpace;
  const mat = new THREE.SpriteMaterial({ map: tex, transparent: true, depthTest: false, depthWrite: false, opacity: 1 });
  const sp = new THREE.Sprite(mat); sp.renderOrder = 25; sp.scale.set(5.2, 1.3, 1);
  return sp;
}
function placeTag(sp, pos, hidden) {
  if (!sp) return;
  sp.position.set(pos.x, pos.y, pos.z + 3.4);
  const d = camera.position.distanceTo(sp.position);
  const a = hidden ? 0 : 1 - THREE.MathUtils.smoothstep(d, TAG_FADE_NEAR, TAG_FADE_FAR);
  sp.material.opacity = a;
  sp.visible = a > 0.02;
}
function disposeTag(sp) { if (!sp) return; scene.remove(sp); if (sp.material.map) sp.material.map.dispose(); sp.material.dispose(); }

function addTrimesh(world, geometry, matrix) {
  const pos = geometry.attributes.position, n = pos.count, e = matrix.elements;
  const verts = new Float32Array(n * 3), idx = new Uint32Array(n);
  for (let i = 0; i < n; i++) { const x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
    verts[i * 3] = e[0] * x + e[4] * y + e[8] * z + e[12]; verts[i * 3 + 1] = e[1] * x + e[5] * y + e[9] * z + e[13]; verts[i * 3 + 2] = e[2] * x + e[6] * y + e[10] * z + e[14]; idx[i] = i; }
  world.createCollider(RAPIER.ColliderDesc.trimesh(verts, idx).setFriction(OBSTACLE_FRICTION).setRestitution(OBSTACLE_RESTITUTION));
}
const wallMat = new THREE.MeshBasicMaterial({ color: 0xff3366, wireframe: true, side: THREE.DoubleSide });
function wallFor(d) { if (d === 'SouthNorth' || d === 'NorthSouth') return { name: 'InvisibleWallStraight', angle: 0 };
  if (d === 'EastWest' || d === 'WestEast') return { name: 'InvisibleWallStraight', angle: 90 };
  let a = 0; if (d === 'SouthEast' || d === 'EastSouth') a = 90; else if (d === 'NorthWest' || d === 'WestNorth') a = -90; else if (d === 'NorthEast' || d === 'EastNorth') a = 180;
  return { name: 'InvisibleWallCorner', angle: a }; }
async function buildWorld(ti) {
  const world = new RAPIER.World({ x: 0, y: 0, z: GRAVITY }); world.timestep = SIM_DT / SUB_STEPS;
  const wg = await loadGLB('InvisibleWall'); const wallGeo = {}; wg.scene.traverse(o => { if (o.isMesh) wallGeo[o.name] = o.geometry; });
  let tris = 0, first = true;
  for (const { inst, tile } of ti) { if (tile.deco) continue;
    inst.updateMatrixWorld(true);
    inst.traverse(o => { if (!o.isMesh) return; if (/Transparent/.test(o.name) || (o.material && /Waves/.test(o.material.name))) return; addTrimesh(world, o.geometry, o.matrixWorld); tris += o.geometry.attributes.position.count / 3; });
    const w = wallFor(tile.direction);
    const m = new THREE.Matrix4().makeRotationZ(THREE.MathUtils.degToRad(w.angle)).setPosition(tile.position.x, tile.position.y, tile.position.z);
    if (wallGeo[w.name]) { addTrimesh(world, wallGeo[w.name], m); const dbg = new THREE.Mesh(wallGeo[w.name], wallMat); dbg.applyMatrix4(m); dbg.visible = false; dbg.userData.collision = true; dbg.userData.wall = true; scene.add(dbg); }
    if (first && wallGeo.InvisibleWallSpecial) { const d = tile.direction, s = 125;
      const off = d === 'SouthNorth' ? [0, -s] : d === 'NorthSouth' ? [0, s] : d === 'WestEast' ? [-s, 0] : [s, 0];
      const ang = (d === 'WestEast' || d === 'EastWest') ? 90 : 0;
      const m2 = new THREE.Matrix4().makeRotationZ(THREE.MathUtils.degToRad(ang)).setPosition(tile.position.x + off[0], tile.position.y + off[1], tile.position.z);
      addTrimesh(world, wallGeo.InvisibleWallSpecial, m2); const dbg = new THREE.Mesh(wallGeo.InvisibleWallSpecial, wallMat); dbg.applyMatrix4(m2); dbg.visible = false; dbg.userData.collision = true; dbg.userData.wall = true; scene.add(dbg); }
    first = false; await new Promise(r => setTimeout(r)); }
  console.log('static collision triangles:', Math.round(tris));
  return world;
}
function makeDriver(world, rig, settings, start) {
  const body = world.createRigidBody(RAPIER.RigidBodyDesc.dynamic().setTranslation(start.x, start.y, start.z + 0.7).setRotation({ x: 0, y: 0, z: 0, w: 1 }).setAngularDamping(1.3).setLinearDamping(LINEAR_DAMPING).setCanSleep(false).setCcdEnabled(true));
  const hull = RAPIER.ColliderDesc.convexHull(rig.proxy); if (!hull) throw new Error('no car hull');
  const collider = world.createCollider(hull.setFriction(settings.friction).setRestitution(settings.restitution).setMass(settings.mass), body);
  collider.setActiveEvents(RAPIER.ActiveEvents.COLLISION_EVENTS);
  const c = body.localCom(); const com = [c.x, c.y, c.z];
  const hw = rig.width * 0.5, wb = rig.wheelBase;
  const wheelPoints = [[com[0] - hw, com[1] + wb, com[2]], [com[0] + hw, com[1] + wb, com[2]], [com[0] - hw, com[1] - wb, com[2]], [com[0] + hw, com[1] - wb, com[2]]];
  const V = (a) => ({ x: a[0], y: a[1], z: a[2] });
  const phys = { position: () => { const t = body.translation(); return [t.x, t.y, t.z]; }, rotation: () => { const r = body.rotation(); return [r.x, r.y, r.z, r.w]; },
    linvel: () => { const v = body.linvel(); return [v.x, v.y, v.z]; }, angvel: () => { const v = body.angvel(); return [v.x, v.y, v.z]; }, com: () => com,
    castRay: (o, d, m) => { const h = world.castRay(new RAPIER.Ray(V(o), V(d)), m, true, undefined, undefined, undefined, body); return h ? (h.timeOfImpact !== undefined ? h.timeOfImpact : h.toi) : null; },
    impulse: v => body.applyImpulse(V(v), true), impulseAt: (v, p) => body.applyImpulseAtPoint(V(v), V(p), true), torqueImpulse: v => body.applyTorqueImpulse(V(v), true), setAngvel: v => body.setAngvel(V(v), true) };
  const car = new HoverCar({ settings, hoverDist: rig.hoverZ0 + settings.hoveroffset, wheelPoints, phys });
  return { body, car, phys, wheelPoints, hoverDist: rig.hoverZ0 + settings.hoveroffset, collider };
}

const keys = new Set();
const input = () => ({ forward: keys.has('KeyW') || keys.has('ArrowUp') ? 1 : 0, backward: keys.has('KeyS') || keys.has('ArrowDown') ? 1 : 0,
  left: keys.has('KeyA') || keys.has('ArrowLeft') ? 1 : 0, right: keys.has('KeyD') || keys.has('ArrowRight') ? 1 : 0,
  brake: keys.has('ShiftLeft') || keys.has('ShiftRight') ? 1 : 0, action1: keys.has('KeyZ') ? 1 : 0, action2: keys.has('KeyX') ? 1 : 0 });
const NO_INPUT = { forward: 0, backward: 0, left: 0, right: 0, brake: 0, action1: 0, action2: 0 };
const cam = { yaw: 0, pitch: -0.2, speed: 40 };
let dragging = false, flyMode = START_FLY, showDebug = false, forceLights = false, menuOpen = false;
let camOffset = new THREE.Vector3(0, -5.5, 1.55), camFov = 55;
let timeScale = 1, fcRoll = 0, fogFar = 600;
renderer.domElement.addEventListener('pointerdown', e => { dragging = true; renderer.domElement.setPointerCapture(e.pointerId); });
renderer.domElement.addEventListener('pointerup', () => { dragging = false; });
renderer.domElement.addEventListener('pointermove', e => {
  if (wheelOpen) { pickWheel(e.clientX, e.clientY); return; }
  if (!dragging || !flyMode) return;
  cam.yaw -= e.movementX * 0.003; cam.pitch = Math.max(-1.5, Math.min(1.5, cam.pitch - e.movementY * 0.003));
});
renderer.domElement.addEventListener('wheel', e => {
  if (flyMode) { camFov = Math.max(20, Math.min(120, camFov + (e.deltaY < 0 ? -3 : 3))); $('fcFov').value = camFov; $('fcFovV').textContent = Math.round(camFov); }
  else cam.speed = Math.max(2, Math.min(600, cam.speed * (e.deltaY < 0 ? 1.15 : 1 / 1.15)));
}, { passive: true });
const chase = { pos: new THREE.Vector3(), yaw: 0, init: false };
const _revOff = new THREE.Vector3(0, 5.5, 1.55);
function updateChase(cp, cf, dt) {
  const rev = keys.has('KeyC');
  const ty = Math.atan2(-cf.x, cf.y);
  if (!chase.init) { chase.pos.copy(cp); chase.yaw = ty; chase.init = true; }
  chase.pos.lerp(cp, 1 - Math.pow(1 - 0.65, dt * TEMPO));
  let d = ty - chase.yaw; d = Math.atan2(Math.sin(d), Math.cos(d)); chase.yaw += d * (1 - Math.pow(1 - 0.13, dt * TEMPO));
  const rot = new THREE.Matrix4().makeRotationZ(chase.yaw);
  camera.position.copy(rev ? _revOff : camOffset).applyMatrix4(rot).add(chase.pos);
  const pitch = THREE.MathUtils.degToRad(8);
  const look = rev ? new THREE.Vector3(0, -Math.cos(pitch), -Math.sin(pitch)) : new THREE.Vector3(0, Math.cos(pitch), -Math.sin(pitch));
  look.applyMatrix4(rot);
  if (camera.fov !== camFov) { camera.fov = camFov; camera.updateProjectionMatrix(); }
  camera.lookAt(camera.position.x + look.x, camera.position.y + look.y, camera.position.z + look.z);
}
const _kcPos = new THREE.Vector3(), _kcLook = new THREE.Vector3(), _kcOff = new THREE.Vector3(0, -9, 3.4);
function updateKillCam(g, dt) {
  const f = new THREE.Vector3(0, 1, 0).applyQuaternion(g.cq);
  const yaw = Math.atan2(-f.x, f.y);
  const rot = new THREE.Matrix4().makeRotationZ(yaw);
  _kcPos.copy(_kcOff).applyMatrix4(rot).add(g.cp);
  camera.position.lerp(_kcPos, 1 - Math.pow(1 - 0.12, dt * TEMPO));
  _kcLook.copy(g.cp); _kcLook.z += 1.2;
  camera.lookAt(_kcLook);
}
function applyEnv() {
  fogFar = Number($('fcFog').value); $('fcFogV').textContent = Math.round(fogFar);
  if (scene.fog) { scene.fog.far = fogFar; scene.fog.near = fogFar * 0.04; }
  const wire = $('fcWire').checked;
  scene.traverse(o => { if (o.isMesh && o.material && !o.userData.collision) o.material.wireframe = wire; });
}
function setFly(on) {
  flyMode = on; $fc.classList.toggle('open', on);
  document.body.classList.toggle('fc', on);
  if (on) { timeScale = 0; $('fcTime').value = 0; $('fcTimeV').textContent = '0.00'; cam.yaw = chase.yaw; cam.pitch = -0.2; }
  else { timeScale = 1; $('fcTime').value = 1; $('fcTimeV').textContent = '1.00'; chase.init = false;
    $('fcDof').value = 0; $('fcMotion').value = 0; $('fcRoll').value = 0; fcRoll = 0; $('fcWire').checked = false; postfx.dof = 0; postfx.motion = 0; applyEnv(); }
}

const game = { health: 200, maxHealth: 200, score: 0, dead: false, respawnAt: 0, hideAt: 0, nitroUntil: 0, popup: '', popupUntil: 0, stuck: 0, countdown: null, damageState: 0,
  lastAttacker: null, lastAttackAt: 0, killCam: null };
function popup(t) { game.popup = t; game.popupUntil = performance.now() + 2500; }
function noteAttacker(id) { if (!id) return; game.lastAttacker = id; game.lastAttackAt = performance.now(); }
function carImpact(d) { if (game.dead) return; game.health -= d; if (game.health <= 0) die(); }
function die() { game.dead = true; game.health = 0; if (playerRec) playerRec.dead = true;
  const t = driver.body.translation();
  fx.explosion({ x: t.x, y: t.y, z: t.z }, { duration: 1500, scale: 1.5 });
  sfx.playAt('Explosion_SFX', t, { volume: 0.9 }); sfx.stopLoop('CarStationair_SFX'); sfx.stopLoop('MiniGun_SFX');
  pushFx({ k: 'boom', p: [t.x, t.y, t.z], d: 1500, s: 1.5, snd: 'Explosion_SFX' });
  const rx = rand(-1, 1), ry = rand(-1, 1), rz = rand(-1, 1);
  driver.body.applyImpulse({ x: rx * 1000, y: ry * 1000, z: 45000 }, true);
  driver.body.applyTorqueImpulse({ x: rx * 450000, y: ry * 450000, z: rz * 550000 }, true);
  if (carVisuals) { carVisuals.setDamage(3); carVisuals.detach(); }
  if (weapons) weapons.detach();
  game.hideAt = performance.now() + WRECK_HOLD; game.respawnAt = performance.now() + 4200;
  if (net && net.racing && game.lastAttacker && performance.now() - game.lastAttackAt < 5000 && ghosts.has(game.lastAttacker)) {
    game.killCam = game.lastAttacker;
    const kg = ghosts.get(game.killCam);
    popup('WRECKED BY ' + String((kg.last && kg.last.name) || 'PLAYER').toUpperCase());
  } else popup('WRECKED!');
}
function damageAI(rec, d) {
  if (rec.dead) return;
  rec.health -= d;
  const f = rec.health / rec.maxHealth;
  if (rec.visuals) rec.visuals.setDamage(f <= 0 ? 3 : f < 0.3 ? 2 : f < 0.6 ? 1 : 0);
  if (rec.health <= 0) { rec.dead = true;
    const t = rec.body.translation();
    fx.explosion({ x: t.x, y: t.y, z: t.z }, { duration: 1200, scale: 1.4 });
    sfx.playAt('Explosion_SFX', t, { volume: 0.7, throttle: 100 });
    if (rec.visuals) rec.visuals.detach();
    if (rec.weapons) rec.weapons.hideAll();
    rec.deadAt = performance.now();
    rec.respawnAt = performance.now() + 3600;
    game.score += 500; popup('+$500'); }
}
function onPickup(p) { const now = performance.now();
  switch (p.kind) {
    case 'Nitro': driver.car.nitro = 1; game.nitroUntil = now + 7500; if (weapons) weapons.setNitro(true); popup('NITRO!'); sfx.play('PickupGeneric', { volume: 0.7 }); sfx.play('NitroStart', { volume: 0.7 }); break;
    case 'Repair': game.health = game.maxHealth; popup('REPAIR!'); sfx.play('PickUpCarRepair', { volume: 0.8 }); break;
    case 'CashSmall': game.score += 1000; popup('+$1000'); sfx.play('PickupCash', { volume: 0.8 }); break;
    case 'CashBig': game.score += 5000; popup('+$5000'); sfx.play('PickupCash', { volume: 0.8 }); break;
    case 'Detonator': props.detonateTile(p.tileIndex, 'Player1'); if (net && net.racing) net.sendDetonate(p.tileIndex); popup('DETONATOR!'); sfx.play('PickupGeneric', { volume: 0.8 }); break;
    case 'HiddenPackage': if (career.hiddenPackages.indexOf(TRACK) < 0) { career.hiddenPackages.push(TRACK); saveCareer(career); } popup('HIDDEN PACKAGE!'); sfx.play('PickupGeneric', { volume: 0.8 }); break;
    case 'Monkey': popup('MONKEY!'); sfx.play('BaboonHit_SFX', { volume: 0.8 }); break;
    case 'Pig': popup('PIG!'); sfx.play('PigHit_SFX', { volume: 0.8 }); break; } }

let carRig = null, driver = null, world = null, skyObj = null, startPose = null, checkpoint = null;
let eventQueue = null, fx = null, sfx = null, props = null, weapons = null, race = null, ai = null, carVisuals = null;
let shared = null, trackInfo = null, resultsShown = false, engineOn = false, countCrops = null;
let combat = null, playerRec = null;
let net = null; const ghosts = new Map(); const ghostPromises = new Map();
const fxQueue = [];
function pushFx(e) { if (net && net.racing) { fxQueue.push(e); if (fxQueue.length > 96) fxQueue.shift(); } }
let aiStarts = [];
const prevMomentum = new THREE.Vector3();
const pose = { prev: null, cur: null };
const readPose = () => { const t = driver.body.translation(), r = driver.body.rotation(); return { p: new THREE.Vector3(t.x, t.y, t.z), q: new THREE.Quaternion(r.x, r.y, r.z, r.w) }; };
function placeBody(p, yaw) {
  driver.body.setTranslation({ x: p.x, y: p.y, z: p.z + 0.7 }, true);
  const h = yaw / 2; driver.body.setRotation({ x: 0, y: 0, z: Math.sin(h), w: Math.cos(h) }, true);
  driver.body.setLinvel({ x: 0, y: 0, z: 0 }, true); driver.body.setAngvel({ x: 0, y: 0, z: 0 }, true);
  driver.car.isHovering = [0, 0, 0, 0];
  pose.prev = pose.cur = readPose(); chase.init = false;
}
function resetCar(useCp) { const p = useCp && checkpoint ? checkpoint : startPose; placeBody(p, p.yaw || 0); if (race) race.reset(); }
function resetToWaypoint() {
  if (!ai || !ai.waypoints.length) { resetCar(true); return; }
  const t = driver.body.translation(); const cur = new THREE.Vector3(t.x, t.y, t.z);
  let best = 0, bd = Infinity;
  for (let i = 0; i < ai.waypoints.length; i++) { const d = ai.waypoints[i].distanceToSquared(cur); if (d < bd) { bd = d; best = i; } }
  const g = ai.waypoints[best], nx = ai.waypoints[(best + 1) % ai.waypoints.length];
  const yaw = Math.atan2(-(nx.x - g.x), (nx.y - g.y));
  placeBody({ x: g.x, y: g.y, z: g.z }, yaw);
}
function damageState() { const f = game.health / game.maxHealth; return game.health <= 0 ? 3 : f < 0.3 ? 2 : f < 0.6 ? 1 : 0; }

async function loadCountdown() {
  try { const g = await loadGLB('1PlayerInterface'); countCrops = {};
    g.scene.traverse(o => { if (!o.isMesh || !o.geometry.attributes.uv) return; const n = o.name.toLowerCase();
      let key = null;
      if (/go/.test(n)) key = 'go'; else if (/(^|[^0-9])3([^0-9]|$)/.test(n)) key = '3'; else if (/(^|[^0-9])2([^0-9]|$)/.test(n)) key = '2'; else if (/(^|[^0-9])1([^0-9]|$)/.test(n)) key = '1';
      if (key && !countCrops[key]) countCrops[key] = uvRect(o); });
  } catch (e) { countCrops = null; }
}
function showCount(label) { const r = countCrops && countCrops[label];
  if (r) { const uw = Math.max(r.u1 - r.u0, 1e-4), vh = Math.max(r.v1 - r.v0, 1e-4), S = 220;
    $cd.style.backgroundImage = `url(${DATA}Shared/Textures/Interface_Texture.png)`;
    $cd.style.backgroundSize = `${S / uw}px ${S / vh}px`;
    $cd.style.backgroundPosition = `${-r.u0 * S / uw}px ${-r.v0 * S / vh}px`;
    $cd.textContent = ''; }
  else { $cd.style.backgroundImage = 'none'; $cd.textContent = label.toUpperCase(); }
  $cd.style.opacity = '1'; }

const emotes = [];
const emoteTexCache = new Map();
function emoteTexture(i) {
  if (emoteTexCache.has(i)) return emoteTexCache.get(i);
  const cv = document.createElement('canvas'); cv.width = cv.height = 128;
  const cx = cv.getContext('2d'); cx.font = '96px serif'; cx.textAlign = 'center'; cx.textBaseline = 'middle';
  cx.fillText(EMOTES[i].e, 64, 70);
  const t = new THREE.CanvasTexture(cv); t.colorSpace = THREE.SRGBColorSpace;
  emoteTexCache.set(i, t); return t;
}
function spawnEmote(i, getPos) {
  const mat = new THREE.SpriteMaterial({ map: emoteTexture(i), transparent: true, depthTest: false, depthWrite: false });
  const sp = new THREE.Sprite(mat); sp.renderOrder = 26; sp.scale.set(0.1, 0.1, 1);
  scene.add(sp); emotes.push({ sp, mat, age: 0, getPos });
  sfx.playAt(EMOTES[i].s, getPos(), { volume: 0.8 });
}
function updateEmotes(dt) {
  for (let i = emotes.length - 1; i >= 0; i--) {
    const e = emotes[i]; e.age += dt; const p = e.getPos();
    const pop = Math.min(1, e.age * 6); const s = 3 * pop * (1 + 0.08 * Math.sin(e.age * 10));
    e.sp.scale.set(s, s, 1);
    e.sp.position.set(p.x, p.y, p.z + 5.4 + Math.sin(e.age * 3) * 0.3 + e.age * 0.6);
    e.mat.opacity = e.age > 1.4 ? Math.max(0, 1 - (e.age - 1.4) / 0.6) : 1;
    if (e.age > 2) { scene.remove(e.sp); e.mat.dispose(); emotes.splice(i, 1); }
  }
}
let wheelOpen = false, wheelSel = 0;
function buildWheel() {
  $wheel.innerHTML = EMOTES.map((em, i) => `<button class="ew" data-i="${i}" style="--a:${i * 45}deg">${em.e}</button>`).join('') + '<div class="ew-hint">release G to send</div>';
  $wheel.querySelectorAll('.ew').forEach(b => { b.onclick = () => { fireEmote(Number(b.dataset.i)); closeWheel(); }; });
}
function pickWheel(x, y) {
  const r = $wheel.getBoundingClientRect();
  const dx = x - (r.left + r.width / 2), dy = y - (r.top + r.height / 2);
  if (Math.hypot(dx, dy) < 30) return;
  let ang = Math.atan2(dy, dx) * 180 / Math.PI + 90; if (ang < 0) ang += 360;
  wheelSel = Math.round(ang / 45) % 8;
  $wheel.querySelectorAll('.ew').forEach((b, i) => b.classList.toggle('sel', i === wheelSel));
}
function openWheel() { if (menuOpen || wheelOpen) return; wheelOpen = true; wheelSel = 0; $wheel.classList.add('open'); $wheel.querySelectorAll('.ew').forEach((b, i) => b.classList.toggle('sel', i === 0)); }
function closeWheel() { wheelOpen = false; $wheel.classList.remove('open'); }
function fireEmote(i) { spawnEmote(i, () => pose.cur ? pose.cur.p : carRig.root.position); if (net && net.racing) net.sendEmote(i); }

function readLoadout() {
  const l = { name: $('netName').value || career.playerName || 'Player', car: $('selCar').value || CAR, primary: $('selPrimary').value || PRIMARY, secondary: $('selSecondary').value || SECONDARY };
  career.playerName = l.name; career.car = l.car; career.primaryWeapon = l.primary; career.secondaryWeapon = l.secondary; saveCareer(career);
  return l;
}
function stubDriver() { return { body: { linvel: () => ({ x: 0, y: 0, z: 0 }), translation: () => ({ x: 0, y: 0, z: 0 }) }, car: { mass: 1 } }; }
async function mountWeapons(rig, cn, primary, secondary, targetScene, hooks, driverObj) {
  const w = new Weapons(Object.assign({ scene: targetScene || scene, world, RAPIER, fx, sfx, loadGLB, loadTexture, texDirs: [`${DATA}Shared/Textures/`], shared, carRig: rig, driver: driverObj || stubDriver(), carCollider: null, carName: cn, upgrades: {}, props: { byCollider: new Map() }, combat: null, tag: 'ghost' }, hooks || {}));
  await w.init(primary, secondary); return w;
}
function ghostRec(g, id) { return { tag: id, id, ghost: true, body: g.body, car: { mass: 3000 }, dead: !g.rig.root.visible }; }
function ensureGhost(m) {
  const id = m.from;
  if (ghosts.has(id)) return Promise.resolve(ghosts.get(id));
  if (ghostPromises.has(id)) return ghostPromises.get(id);
  const pr = (async () => {
    const cn = m.car || 'BMW';
    const { kit } = await loadCarData(cn);
    const rig = await loadCar(cn, kit, null);
    const velRef = { x: 0, y: 0, z: 0 };
    const posRef = { x: m.p[0], y: m.p[1], z: m.p[2] };
    const ghostDriver = { body: { linvel: () => velRef, translation: () => posRef }, car: { mass: 3000 } };
    const gw = await mountWeapons(rig, cn, m.primary || 'MachineGun', m.secondary || 'RocketPod', null, null, ghostDriver);
    let body = null;
    if (world && RAPIER && rig.proxy) {
      body = world.createRigidBody(RAPIER.RigidBodyDesc.kinematicPositionBased().setTranslation(m.p[0], m.p[1], m.p[2]));
      const col = world.createCollider(RAPIER.ColliderDesc.convexHull(rig.proxy).setFriction(0.35).setRestitution(0.4), body);
      if (combat) combat.byCollider.set(col.handle, ghostRec({ rig, body }, id));
    }
    const tagSprite = makeNametag(m.name || 'PLAYER', '#4da3ff');
    scene.add(tagSprite);
    const g = { rig, weapons: gw, body, tagSprite, tagName: m.name || 'PLAYER', velRef, posRef,
      visuals: setupCarVisuals(rig, cn, () => ghostDriver.body), last: m, wasDead: false, deadAt: 0,
      tp: new THREE.Vector3(m.p[0], m.p[1], m.p[2]), tq: new THREE.Quaternion(m.q[0], m.q[1], m.q[2], m.q[3]),
      cp: new THREE.Vector3(m.p[0], m.p[1], m.p[2]), cq: new THREE.Quaternion(m.q[0], m.q[1], m.q[2], m.q[3]) };
    ghosts.set(id, g); ghostPromises.delete(id);
    return g;
  })();
  ghostPromises.set(id, pr);
  return pr;
}
function removeGhost(id) { const g = ghosts.get(id); if (!g) return;
  if (g.weapons) { g.weapons.clearVisuals(); g.weapons.cleanup(); }
  if (g.visuals) { g.visuals.cleanup(); scene.remove(g.visuals.shadow); }
  disposeTag(g.tagSprite);
  scene.remove(g.rig.root); if (g.body) world.removeRigidBody(g.body);
  if (game.killCam === id) game.killCam = null;
  ghosts.delete(id); }
function applyGhostState(m) {
  ensureGhost(m).then(g => {
    g.last = m; g.tp.set(m.p[0], m.p[1], m.p[2]); g.tq.set(m.q[0], m.q[1], m.q[2], m.q[3]);
    if (m.name && m.name !== g.tagName) {
      g.tagName = m.name; disposeTag(g.tagSprite);
      g.tagSprite = makeNametag(m.name, '#4da3ff'); scene.add(g.tagSprite);
    }
  });
}
const _gq = new THREE.Quaternion(), _gqs = new THREE.Quaternion(), _gqa = new THREE.Quaternion();
const AX = new THREE.Vector3(1, 0, 0), AZ = new THREE.Vector3(0, 0, 1);
function updateGhosts() {
  const now = performance.now();
  for (const [id, g] of ghosts) {
    const m = g.last || {};
    g.velRef.x = (g.tp.x - g.cp.x) * 18; g.velRef.y = (g.tp.y - g.cp.y) * 18; g.velRef.z = (g.tp.z - g.cp.z) * 18;
    g.cp.lerp(g.tp, 0.3); g.cq.slerp(g.tq, 0.3);
    g.posRef.x = g.cp.x; g.posRef.y = g.cp.y; g.posRef.z = g.cp.z;
    g.rig.root.position.copy(g.cp); g.rig.root.quaternion.copy(g.cq);
    g.rig.body.rotation.set(0, THREE.MathUtils.degToRad(m.bank || 0), 0);

    // wreck parity: throw debris, keep the hull visible for the same hold as the owner
    if (m.dead && !g.wasDead) {
      g.wasDead = true; g.deadAt = now;
      if (g.visuals) { g.visuals.setDamage(3); g.visuals.detach(); }
      if (g.weapons) g.weapons.detach();
    } else if (!m.dead && g.wasDead) {
      g.wasDead = false;
      if (g.visuals) { g.visuals.cleanup(); g.visuals.setDamage(0); }
      if (g.weapons) g.weapons.cleanup();
    }
    g.rig.root.visible = !g.wasDead || (now - g.deadAt < WRECK_HOLD);

    if (!g.rig.hideWheels && !g.wasDead) {
      const hov = m.h || null, hd = m.hd || (g.rig.hoverZ0 + 0.25);
      for (let i = 0; i < 4; i++) {
        const w = g.rig.wheels[i], rl = g.rig.restLocal[i];
        const L = hov ? hov[i] : hd;
        w.position.set(rl.x, rl.y, rl.z + (hd - L));
        const right = i === 1 || i === 3, front = i < 2;
        _gq.setFromAxisAngle(AX, THREE.MathUtils.degToRad(right ? -(m.spin || 0) : (m.spin || 0)));
        if (front) { _gqs.setFromAxisAngle(AZ, -THREE.MathUtils.degToRad(28 * (m.turn || 0))); _gq.premultiply(_gqs); }
        if (right) { _gqa.setFromAxisAngle(AZ, Math.PI); _gq.premultiply(_gqa); }
        w.quaternion.copy(_gq);
      }
    }
    for (const l of g.rig.lights.rear) l.visible = !!m.brake && !g.wasDead;
    for (const l of g.rig.lights.front) l.visible = !!m.lights && !g.wasDead;
    placeTag(g.tagSprite, g.cp, g.wasDead);
    if (g.visuals) {
      if (!g.wasDead) g.visuals.setDamage(m.dmg || 0);
      const f = new THREE.Vector3(0, 1, 0).applyQuaternion(g.cq);
      g.visuals.updateShadow(g.cp, Math.atan2(-f.x, f.y), g.body);
      g.visuals.updateDebris();
    }
    if (g.weapons) {
      g.weapons.setNitro(!!m.nitro && !g.wasDead);
      g.weapons.setBarrels(m.barrel || 0);
      if (m.laser) g.weapons.setLaser(m.laser.c, m.laser.f, m.laser.l);
      if (!g.wasDead) g.weapons.equipped.forEach((w, wi) => {
        if (w.tracers.length || w.type === 'laser') return;
        const on = wi === 0 ? m.fire1 : m.fire2;
        for (const fl of w.flashes) for (const f of fl) f.scale.setScalar(on ? 1.3 : 0.001);
      });
      g.weapons.updateDebris();
    }
    if (g.body) { g.body.setNextKinematicTranslation({ x: g.cp.x, y: g.cp.y, z: g.cp.z }); g.body.setNextKinematicRotation({ x: g.cq.x, y: g.cq.y, z: g.cq.z, w: g.cq.w }); }
  }
}
// replica projectiles advance on the fixed 32 Hz tick so lifetimes match the owner exactly
function tickGhostVisuals() { for (const g of ghosts.values()) if (g.weapons) g.weapons.updateVisuals(); }
function handleFx(m) {
  const g = ghosts.get(m.from);
  for (const e of (m.e || [])) {
    if (e.k === 'boom') {
      const p = new THREE.Vector3(e.p[0], e.p[1], e.p[2]);
      fx.explosion(p, { duration: e.d || 500, scale: e.s || 1 });
      sfx.playAt(e.snd || 'RocketPodExplosion_SFX', p, { volume: 0.7, throttle: 60 });
      for (const gg of ghosts.values()) if (gg.weapons) gg.weapons.removeVisualsNear(p, 4.5);
    }
    else if (e.k === 'spark') { const p = new THREE.Vector3(e.p[0], e.p[1], e.p[2]); fx.spark(p); sfx.hit(e.t || 'none', p, 0.45); }
    else if (e.k === 'shot' && g && g.weapons) g.weapons.spawnVisual(e.kind, e);
    else if (e.k === 'tr' && g && g.weapons) g.weapons.showTracer(e.mi, e.o, e.q, e.dist, e.mini);
  }
}
let netTick = 0;
function broadcastPose() {
  if (!net || !net.racing || !pose.cur) return;
  if (fxQueue.length) net.sendFx(fxQueue.splice(0));
  if ((netTick++ % 2) !== 0) return;
  const inp = input();
  const c = driver.car;
  const h = [0, 1, 2, 3].map(i => c.isHovering[i] ? c.hoverDists[i] : driver.hoverDist);
  net.broadcastState({ name: (net.loadout && net.loadout.name) || career.playerName || 'Player',
    car: CAR, primary: PRIMARY, secondary: SECONDARY,
    p: [pose.cur.p.x, pose.cur.p.y, pose.cur.p.z], q: [pose.cur.q.x, pose.cur.q.y, pose.cur.q.z, pose.cur.q.w],
    spin: c.wheelSpin, turn: c.wheelTurn, bank: c.bankAngle, h, hd: driver.hoverDist,
    brake: !!(forceLights || inp.backward || inp.brake), lights: !!forceLights,
    nitro: c.nitro > 0, fire1: !!inp.action1, fire2: !!inp.action2,
    barrel: weapons ? weapons.barrelAngle() : 0, laser: weapons ? weapons.laserState() : null,
    dmg: game.damageState, dead: game.dead, health: game.health });
}
function assignOnlineSlot() {
  if (!net || !ROOM) return;
  const ids = net.slotIds(); const slot = Math.max(0, ids.indexOf(net.id));
  const st = slot === 0 ? startPose : (aiStarts[slot - 1] || startPose);
  placeBody({ x: st.x, y: st.y, z: st.z }, 0);
}

let previewRenderer = null, previewScene = null, previewCam = null, previewGroup = null, previewToken = 0, previewSig = '';
function initPreview() {
  if (previewRenderer) return;
  previewRenderer = new THREE.WebGLRenderer({ canvas: $('previewCanvas'), antialias: true, alpha: true });
  previewRenderer.setPixelRatio(1); previewRenderer.setSize(660, 240, false);
  previewRenderer.setClearColor(0x000000, 0);
  previewScene = new THREE.Scene();
  previewCam = new THREE.PerspectiveCamera(40, 660 / 240, 0.1, 300);
  previewCam.up.set(0, 0, 1);
  previewCam.position.set(0, -11, 3.4); previewCam.lookAt(0, 0, 0.8);
  previewGroup = new THREE.Group(); previewScene.add(previewGroup);
  const ground = new THREE.Mesh(new THREE.CircleGeometry(9, 48), new THREE.MeshBasicMaterial({ color: 0x232c3d }));
  ground.position.z = -0.45; previewGroup.add(ground);
}
async function rebuildPreview(room) {
  initPreview();
  const players = (room.players || []).slice();
  const sig = players.map(p => p.id + p.car + p.primary + p.secondary).join('|');
  if (sig === previewSig) return; previewSig = sig;
  const token = ++previewToken;
  const built = [];
  for (const pl of players) {
    try { const { kit } = await loadCarData(pl.car);
      const rig = await loadCar(pl.car, kit, null, previewScene);
      await mountWeapons(rig, pl.car, pl.primary, pl.secondary, previewScene);
      const tag = makeNametag(pl.name || 'PLAYER', pl.id === net.id ? '#e8322b' : '#4da3ff');
      tag.position.set(0, 0, 3.4); rig.root.add(tag);
      built.push(rig);
    } catch (e) { console.warn('preview car', e); }
    if (token !== previewToken) { for (const r of built) previewScene.remove(r.root); return; }
  }
  if (token !== previewToken) return;
  while (previewGroup.children.length > 1) previewGroup.remove(previewGroup.children[1]);
  if (!built.length && carRig) { const c = carRig.root.clone(true); c.rotation.set(0, 0, 0); previewScene.add(c); built.push({ root: c }); }
  const n = built.length;
  built.forEach((rig, i) => { previewGroup.add(rig.root); rig.root.position.set((i - (n - 1) / 2) * 5.5, 0, 0); rig.root.rotation.set(0, 0, 0.5); });
}
function renderPreview() { if (!previewRenderer || !$('lobby').classList.contains('open')) return;
  previewGroup.rotation.z += 0.004; previewRenderer.render(previewScene, previewCam); }

function wireNet() {
  net.onState = applyGhostState; net.onPeerLeave = removeGhost; net.onFx = handleFx;
  net.onEmote = m => { const g = ghosts.get(m.from); if (g) spawnEmote(m.e, () => g.cp); };
  net.onHit = m => { if (m.to === net.id) { noteAttacker(m.from); carImpact(m.d); } };
  net.onProp = m => { if (props) props.destroyIndex(m.i); };
  net.onDetonate = m => { if (props) props.detonateTile(m.tile, 'remote'); };
}
function openOnline() {
  $('menu').classList.remove('open'); $('online').classList.add('open');
  if (!net) { net = new Net(WS);
    net.onLobby = rooms => { const el = $('roomList'); el.innerHTML = rooms.length ? rooms.map(r => `<div class="item"><span class="nm">${r.name} · ${r.track} · ${r.players.length}p</span><button data-room="${r.id}">JOIN</button></div>`).join('') : '<div class="sub">No rooms yet — create one.</div>';
      el.querySelectorAll('button[data-room]').forEach(b => b.onclick = () => { const room = net.rooms.get(b.dataset.room); if (room) { net.setLoadout(readLoadout()); net.joinRoom(room); openLobby(); } }); };
    net.onRoom = room => { if ($('lobby').classList.contains('open')) { renderLobby(room); rebuildPreview(room); } };
    net.onStart = (track, roomId) => { const q = new URLSearchParams(location.search); q.set('track', track); q.set('autostart', '1'); q.set('room', roomId); q.set('car', career.car); q.set('primary', career.primaryWeapon); q.set('secondary', career.secondaryWeapon); q.set('name', career.playerName || 'Player'); if (WS) q.set('ws', WS); location.search = q.toString(); };
    wireNet();
  }
  net.setLoadout(readLoadout());
}
function openLobby() { $('online').classList.remove('open'); $('lobby').classList.add('open'); renderLobby(net.room); rebuildPreview(net.room); }
function renderLobby(room) {
  $('lobbyTitle').textContent = room.name || 'Room';
  $('lobbyTrack').textContent = room.track || TRACK;
  $('playerList').innerHTML = (room.players || []).map(p => `<div class="item"><span class="nm">${p.name} · ${p.car}</span><span class="nm">${p.primary} / ${p.secondary}</span></div>`).join('');
  $('btnBegin').style.display = net.isHost ? '' : 'none';
}
$('btnOnline').onclick = openOnline;
$('btnCreate').onclick = () => { const name = $('roomName').value || 'Room'; const track = $('roomTrack').value; net.setLoadout(readLoadout()); net.createRoom(name, track); openLobby(); };
$('btnBegin').onclick = () => net.beginRace();
$('btnLeave').onclick = () => { net.leave(); $('lobby').classList.remove('open'); $('menu').classList.add('open'); };
$('btnBackOnline').onclick = () => { $('online').classList.remove('open'); $('menu').classList.add('open'); };

const _listenerFwd = new THREE.Vector3(), _listenerUp = new THREE.Vector3(0, 0, 1);
function gameTick() {
  const now = performance.now();
  if (game.countdown !== null && game.countdown > 0) {
    game.countdown -= 1 / TEMPO;
    if (game.countdown <= 0) { game.countdown = null; showCount('go'); setTimeout(() => { $cd.style.opacity = '0'; }, 700); }
    else showCount(String(Math.ceil(game.countdown)));
    return;
  }
  const inp = (flyMode || game.dead || menuOpen) ? NO_INPUT : input();
  const out = driver.car.step(inp);
  let contact = false, contactOther = null; const ch = driver.collider.handle;
  for (let i = 0; i < SUB_STEPS; i++) world.step(eventQueue);
  eventQueue.drainCollisionEvents((a, b, s) => { if (s && (a === ch || b === ch)) { contact = true; contactOther = a === ch ? b : a; } });
  const v = driver.body.linvel(), m = driver.car.mass;
  const mom = new THREE.Vector3(v.x * m, v.y * m, v.z * m);
  if (contact && !game.dead) { const f = mom.distanceTo(prevMomentum) * 0.00003;
    if (f > 0.002) {
      const rec = contactOther != null && combat ? combat.byCollider.get(contactOther) : null;
      if (rec && rec.ghost) noteAttacker(rec.id);
      carImpact(f);
      if (f >= 0.02) sfx.playAt('Bump_SFX', pose.cur ? pose.cur.p : driver.body.translation(), { volume: Math.min(0.8, f * 4), rate: 0.9 + Math.random() * 0.3, throttle: 120 }); } }
  prevMomentum.copy(mom);
  pose.prev = pose.cur; pose.cur = readPose();
  if (!game.dead && !menuOpen && Math.abs(driver.car.speed) < 0.5 && ((inp.forward || inp.backward) || driver.car.hovering === 0)) game.stuck += 1 / TEMPO; else game.stuck = 0;
  if (game.stuck > 1.2) { game.stuck = 0; resetToWaypoint(); }
  const c = driver.car;
  if (!game.dead && c.hovering && c.upright > 0.9 && Math.abs(c.speed) > 2 && (++checkpoint.n % 16 === 0)) {
    const f = new THREE.Vector3(0, 1, 0).applyQuaternion(pose.cur.q);
    Object.assign(checkpoint, { x: pose.cur.p.x, y: pose.cur.p.y, z: pose.cur.p.z - 0.2, yaw: Math.atan2(-f.x, f.y) }); }
  if (out.reset && !game.dead) resetToWaypoint();
  const rearOn = forceLights || inp.backward;
  for (const mm of carRig.lights.rear) mm.visible = !!rearOn;
  for (const mm of carRig.lights.front) mm.visible = forceLights;
  props.update(game.dead ? null : pose.cur.p, now);
  if (race && !game.dead && !menuOpen) race.update(pose.cur.p, driver.car.speed, now);
  if (ai && !menuOpen) ai.update(now);
  if (weapons) weapons.update(inp);
  tickGhostVisuals();
  broadcastPose();
  if (game.nitroUntil && now >= game.nitroUntil) { game.nitroUntil = 0; driver.car.nitro = 0; if (weapons) weapons.setNitro(false); }
  const ds = damageState();
  if (ds !== game.damageState && !game.dead) { game.damageState = ds; if (carVisuals) carVisuals.setDamage(ds); }
  if (game.dead) {
    if (game.hideAt && now >= game.hideAt) { carRig.root.visible = false; game.hideAt = 0; }
    if (now >= game.respawnAt) { game.dead = false; game.health = game.maxHealth; game.damageState = 0; if (playerRec) playerRec.dead = false;
      game.killCam = null; game.lastAttacker = null; chase.init = false;
      carRig.root.visible = true; if (carVisuals) { carVisuals.cleanup(); carVisuals.setDamage(0); }
      if (weapons) weapons.cleanup();
      driver.car.nitro = 0; game.nitroUntil = 0; if (weapons) weapons.setNitro(false);
      resetToWaypoint(); } }
  const wantEngine = !menuOpen && !game.dead && !flyMode && game.countdown === null;
  if (wantEngine) { sfx.startLoop('CarStationair_SFX', { volume: 0.35, rate: 0.5 + c.speedPerc * 1.6 }); engineOn = true; }
  else if (engineOn) { sfx.stopLoop('CarStationair_SFX'); engineOn = false; }
  if (race && race.finished && !resultsShown) showResults();
}
const _q = new THREE.Quaternion(), _qs = new THREE.Quaternion(), _qa = new THREE.Quaternion();
function updateCarVisual(alpha) {
  const p = pose.prev.p.clone().lerp(pose.cur.p, alpha), q = pose.prev.q.clone().slerp(pose.cur.q, alpha);
  carRig.root.position.copy(p); carRig.root.quaternion.copy(q);
  carRig.body.rotation.set(0, THREE.MathUtils.degToRad(driver.car.bankAngle), 0);
  if (!carRig.hideWheels) for (let i = 0; i < 4; i++) {
    const w = carRig.wheels[i], wp = driver.wheelPoints[i];
    const L = driver.car.isHovering[i] ? driver.car.hoverDists[i] : driver.hoverDist;
    w.position.set(wp[0], wp[1] + carRig.radiusDEV, wp[2] - L + carRig.radius);
    const right = i === 1 || i === 3, front = i < 2;
    _q.setFromAxisAngle(AX, THREE.MathUtils.degToRad(right ? -driver.car.wheelSpin : driver.car.wheelSpin));
    if (front) { _qs.setFromAxisAngle(AZ, -THREE.MathUtils.degToRad(driver.car.maxWheelTurn * driver.car.wheelTurn)); _q.premultiply(_qs); }
    if (right) { _qa.setFromAxisAngle(AZ, Math.PI); _q.premultiply(_qa); }
    w.quaternion.copy(_q); }
  if (carVisuals) { const f = new THREE.Vector3(0, 1, 0).applyQuaternion(q); carVisuals.updateShadow(p, Math.atan2(-f.x, f.y), driver.body); }
  return { p, q };
}
const fwd = new THREE.Vector3(), rightV = new THREE.Vector3(), upV = new THREE.Vector3(0, 0, 1);
let last = performance.now(), acc = 0, frames = 0, fpsT = last, fps = 0, hudBase = '', hudT = 0;
const RING_C = 2 * Math.PI * 26;
function ghostName(id, g) { return (g && g.last && g.last.name) || (net && net.peers.get(id) && net.peers.get(id).name) || 'PLAYER'; }
function standings() {
  const G = (race && race.gates.length) || 1;
  const list = [{ name: (career.playerName || 'PLAYER'), prog: (race ? (race.lap - 1) * G + race.next : 0), me: true }];
  if (ai) for (const a of ai.cars) list.push({ name: a.name, prog: ai.progress(a), me: false });
  for (const [id, g] of ghosts) list.push({ name: ghostName(id, g), prog: (g.last && g.last.prog) || 0, me: false });
  list.sort((x, y) => y.prog - x.prog);
  return list;
}
function fmtTime(ms) { const t = Math.max(0, ms); const m = Math.floor(t / 60000), s = Math.floor(t / 1000) % 60, h = Math.floor(t / 10) % 100;
  return `${m}:${String(s).padStart(2, '0')}:${String(h).padStart(2, '0')}`; }
function hudInfo() {
  const c = driver ? driver.car : null;
  $('raceCash').textContent = '$' + String(game.score).padStart(6, '0').replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  $('raceTime').textContent = race ? fmtTime(race.finished ? race.total : (race.started ? performance.now() - race.t0 : 0)) : '0:00:00';
  const st = standings();
  $('standings').innerHTML = st.map((r, i) => `<div class="srow${r.me ? ' me' : ''}"><span class="nm">${String(r.name).toUpperCase()}</span><span class="pos">${i + 1}</span></div>`).join('');
  $('speed').textContent = c ? String(Math.round(Math.abs(c.speed))).padStart(3, '0') : '000';
  const hb = $('healthbar'); if (hb) hb.style.width = Math.max(0, Math.round(100 * game.health / game.maxHealth)) + '%';
  if (weapons) {
    const a = weapons.ammoInfo();
    const setG = (ring, num, name, info) => {
      if (!info) { $(ring).style.strokeDashoffset = RING_C; $(num).textContent = '–'; $(name).textContent = 'NONE'; return; }
      const frac = info.clipsMax ? info.clips / info.clipsMax : 0;
      $(ring).style.strokeDashoffset = RING_C * (1 - frac);
      $(num).textContent = info.ammo; $(name).textContent = info.name;
    };
    setG('ringP', 'ammoP', 'nameP', a[0]);
    setG('ringS', 'ammoS', 'nameS', a[1]);
  }
  if ($popup) { const on = performance.now() < game.popupUntil; $popup.style.opacity = on ? '1' : '0'; if (on) $popup.textContent = game.popup; }
}
function tick(now) {
  const dt = Math.min(0.1, (now - last) / 1000); last = now;
  const sdt = dt * timeScale;
  if (driver) { acc += sdt; while (acc >= 1 / TEMPO) { gameTick(); acc -= 1 / TEMPO; }
    const { p, q } = updateCarVisual(acc * TEMPO);
    if (!flyMode) {
      const kc = game.dead && game.killCam ? ghosts.get(game.killCam) : null;
      if (kc) updateKillCam(kc, dt);
      else updateChase(p, new THREE.Vector3(0, 1, 0).applyQuaternion(q), dt);
    } }
  if (props) props.render(acc * TEMPO, camera.position);
  if (ai) { ai.render(acc * TEMPO);
    const nowMs = performance.now();
    for (const a of ai.cars) {
      if (a.dead) { a.rig.root.visible = nowMs - (a.deadAt || 0) < WRECK_HOLD; }
      placeTag(a.tagSprite, a.rig.root.position, a.rig.root.visible === false);
      if (a.visuals) { a.visuals.updateDebris();
        if (a.rig.root.visible) { const f = new THREE.Vector3(0, 1, 0).applyQuaternion(a.rig.root.quaternion); a.visuals.updateShadow(a.rig.root.position, Math.atan2(-f.x, f.y), a.body); } } } }
  updateGhosts();
  updateEmotes(sdt);
  if (carVisuals) carVisuals.updateDebris();
  if (weapons) weapons.updateDebris();
  if (flyMode || !driver) {
    fwd.set(-Math.sin(cam.yaw) * Math.cos(cam.pitch), Math.cos(cam.yaw) * Math.cos(cam.pitch), Math.sin(cam.pitch));
    rightV.set(Math.cos(cam.yaw), Math.sin(cam.yaw), 0);
    const v = cam.speed * (keys.has('ShiftLeft') || keys.has('ShiftRight') ? 4 : 1) * dt;
    if (keys.has('KeyW')) camera.position.addScaledVector(fwd, v);
    if (keys.has('KeyS')) camera.position.addScaledVector(fwd, -v);
    if (keys.has('KeyD')) camera.position.addScaledVector(rightV, v);
    if (keys.has('KeyA')) camera.position.addScaledVector(rightV, -v);
    if (keys.has('KeyE')) camera.position.addScaledVector(upV, v);
    if (keys.has('KeyQ')) camera.position.addScaledVector(upV, -v);
    camera.lookAt(camera.position.x + fwd.x, camera.position.y + fwd.y, camera.position.z + fwd.z);
    if (camera.fov !== camFov) { camera.fov = camFov; camera.updateProjectionMatrix(); }
  }
  camera.rotateZ(THREE.MathUtils.degToRad(fcRoll));
  if (skyObj) skyObj.position.copy(camera.position);
  if (fx) fx.update(sdt * TEMPO, camera);
  if (sfx) { camera.getWorldDirection(_listenerFwd); sfx.setListener(camera.position, _listenerFwd, _listenerUp); }
  postfx.dof = flyMode ? Number($('fcDof').value) : 0;
  postfx.motion = flyMode ? Number($('fcMotion').value) / 100 : 0;
  postfx.focus = pose.cur ? camera.position.distanceTo(pose.cur.p) : 30;
  renderer.info.reset();
  postfx.render(skyScene, scene, camera);
  renderPreview();
  frames++; if (now - fpsT > 1000) { fps = Math.round(frames * 1000 / (now - fpsT)); frames = 0; fpsT = now; }
  if (now - hudT > 120) { hudT = now; hudInfo(); }
  requestAnimationFrame(tick); }
window.addEventListener('keydown', e => {
  if (e.repeat) { keys.add(e.code); return; }
  keys.add(e.code); if (sfx) sfx.unlock();
  if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) e.preventDefault();
  if (e.code === 'Escape') { toggleMenu(); return; }
  if (menuOpen) return;
  if (e.code === 'KeyG') { openWheel(); return; }
  if (wheelOpen && /^Digit[1-8]$/.test(e.code)) { fireEmote(Number(e.code.slice(5)) - 1); closeWheel(); return; }
  if (e.code === 'KeyF' && driver) setFly(!flyMode);
  if (e.code === 'KeyR' && driver && !flyMode && !game.dead) resetToWaypoint();
  if (e.code === 'KeyL') forceLights = !forceLights;
  if (e.code === 'KeyM' && sfx) { sfx.enabled = !sfx.enabled; popup(sfx.enabled ? 'SOUND ON' : 'SOUND OFF'); }
  if (e.code === 'KeyV') { showDebug = !showDebug; scene.traverse(o => { if (o.userData && o.userData.collision && o.isMesh) { o.visible = showDebug; if (!o.userData.wall) o.material = wallMat; } }); }
});
window.addEventListener('keyup', e => { keys.delete(e.code); if (e.code === 'KeyG' && wheelOpen) { fireEmote(wheelSel); closeWheel(); } });
$('fcTime').addEventListener('input', e => { timeScale = Number(e.target.value); $('fcTimeV').textContent = timeScale.toFixed(2); });
$('fcFov').addEventListener('input', e => { camFov = Number(e.target.value); $('fcFovV').textContent = Math.round(camFov); });
$('fcRoll').addEventListener('input', e => { fcRoll = Number(e.target.value); $('fcRollV').textContent = Math.round(fcRoll); });
$('fcSpeed').addEventListener('input', e => { cam.speed = Number(e.target.value); $('fcSpeedV').textContent = Math.round(cam.speed); });
$('fcDof').addEventListener('input', e => { $('fcDofV').textContent = Math.round(Number(e.target.value)); });
$('fcMotion').addEventListener('input', e => { $('fcMotionV').textContent = Math.round(Number(e.target.value)); });
$('fcFog').addEventListener('input', applyEnv);
$('fcWire').addEventListener('change', applyEnv);
$('fcReset').addEventListener('click', () => { $('fcTime').value = 0; timeScale = 0; $('fcTimeV').textContent = '0.00';
  $('fcFov').value = 55; camFov = 55; $('fcFovV').textContent = '55'; $('fcRoll').value = 0; fcRoll = 0; $('fcRollV').textContent = '0';
  $('fcSpeed').value = 40; cam.speed = 40; $('fcSpeedV').textContent = '40'; $('fcDof').value = 0; $('fcDofV').textContent = '0';
  $('fcMotion').value = 0; $('fcMotionV').textContent = '0'; $('fcFog').value = 600; $('fcWire').checked = false; applyEnv(); });

function navWith(l, auto, extra) { const q = new URLSearchParams(location.search); q.set('track', l.track || TRACK); q.set('car', l.car); q.set('primary', l.primaryWeapon); q.set('secondary', l.secondaryWeapon); if (auto) q.set('autostart', '1'); else q.delete('autostart'); if (extra) for (const [k, v] of Object.entries(extra)) q.set(k, v); location.search = q.toString(); }
function toggleMenu(f) { menuOpen = f !== undefined ? f : !menuOpen; $menu.classList.toggle('open', menuOpen); if (menuOpen) { $results.classList.remove('open'); buildMenu(); } }
function buildMenu() { $('menuCash').textContent = '$' + career.cash;
  const fill = (sel, ids, cur, labels) => { sel.innerHTML = ''; for (const id of ids) { const o = document.createElement('option'); o.value = id; o.textContent = (labels && labels[id]) || id; if (id === cur) o.selected = true; sel.appendChild(o); } };
  const pl = {}, sl = {}, tl = {};
  for (const [id, label] of TRACKS) tl[id] = label;
  if (shared) { for (const k of Object.keys(shared.primaryWeapons)) pl[k] = shared.primaryWeapons[k].name || k; for (const k of Object.keys(shared.secondaryWeapons)) sl[k] = shared.secondaryWeapons[k].name || k; }
  fill($('selTrack'), TRACKS.map(t => t[0]), TRACK, tl);
  fill($('roomTrack'), TRACKS.map(t => t[0]), TRACK, tl);
  fill($('selCar'), career.cars, career.car);
  fill($('selPrimary'), career.primary, career.primaryWeapon, pl);
  fill($('selSecondary'), career.secondary, career.secondaryWeapon, sl);
  if ($('netName') && !$('netName').value) $('netName').value = career.playerName || 'Player';
  const shop = $('shop'); shop.innerHTML = '';
  const addItem = (kind, id, cost, label) => { const owned = isUnlocked(career, kind, id);
    const d = document.createElement('div'); d.className = 'item';
    const nm = document.createElement('span'); nm.className = 'nm'; nm.textContent = label || id;
    const b = document.createElement('button'); b.textContent = owned ? 'Owned' : '$' + cost; b.disabled = owned || career.cash < cost;
    b.onclick = () => { addCash(career, -cost); unlock(career, kind, id); buildMenu(); };
    d.appendChild(nm); d.appendChild(b); shop.appendChild(d); };
  for (const c of AVAILABLE_CARS) if (!isUnlocked(career, 'car', c)) addItem('car', c, 50000, c);
  if (shared) { for (const k of Object.keys(shared.primaryWeapons)) { const w = shared.primaryWeapons[k]; if (k !== 'Default' && !isUnlocked(career, 'primary', k)) addItem('primary', k, w.cost || 0, w.name || k); }
    for (const k of Object.keys(shared.secondaryWeapons)) { const w = shared.secondaryWeapons[k]; if (k !== 'Default' && !isUnlocked(career, 'secondary', k)) addItem('secondary', k, w.cost || 0, w.name || k); } } }
function settle() {
  for (let i = 0; i < 60; i++) { driver.car.step(NO_INPUT); if (ai) for (const a of ai.cars) a.car.step(NO_INPUT);
    for (let s = 0; s < SUB_STEPS; s++) world.step(eventQueue); }
  eventQueue.drainCollisionEvents(() => {});
  pose.prev = pose.cur = readPose();
  if (ai) for (const a of ai.cars) { const t = a.body.translation(), r = a.body.rotation(); a.cp.set(t.x, t.y, t.z); a.cq.set(r.x, r.y, r.z, r.w); a.pp.copy(a.cp); a.pq.copy(a.cq); }
}
function startRace() { $results.classList.remove('open'); resultsShown = false; toggleMenu(false);
  if (race) race.reset(); resetCar(false);
  driver.body.setLinvel({ x: 0, y: 0, z: 0 }, true); driver.body.setAngvel({ x: 0, y: 0, z: 0 }, true);
  if (ai) for (const a of ai.cars) { a.body.setLinvel({ x: 0, y: 0, z: 0 }, true); a.body.setAngvel({ x: 0, y: 0, z: 0 }, true); }
  settle(); game.countdown = 3.5;
  if (ROOM) setTimeout(assignOnlineSlot, 1500); }
$('btnStart').onclick = () => { const sel = { track: $('selTrack').value, car: $('selCar').value, primaryWeapon: $('selPrimary').value, secondaryWeapon: $('selSecondary').value };
  career.car = sel.car; career.primaryWeapon = sel.primaryWeapon; career.secondaryWeapon = sel.secondaryWeapon; saveCareer(career);
  if (sel.track === TRACK && sel.car === CAR && sel.primaryWeapon === PRIMARY && sel.secondaryWeapon === SECONDARY) startRace(); else navWith(sel, true); };
$('btnFree').onclick = () => { $results.classList.remove('open'); toggleMenu(false); if (race) race.reset(); };
$('btnRetry').onclick = () => navWith(career, true, ROOM ? { room: ROOM, name: career.playerName || 'Player' } : null);
$('btnGarage').onclick = () => { $results.classList.remove('open'); toggleMenu(true); };
function showResults() { resultsShown = true; const t = race.total;
  const beat = trackInfo && trackInfo.targetTime ? t < trackInfo.targetTime : false;
  const prize = 5000 + Math.floor(game.score / 10) + (beat ? 10000 : 0);
  addCash(career, prize);
  const best = career.bestTimes[TRACK]; if (!best || t < best) { career.bestTimes[TRACK] = t; saveCareer(career); }
  $('resTime').textContent = (t / 1000).toFixed(2) + 's';
  $('resDetail').textContent = `Score $${game.score} · prize +$${prize}${beat ? ' (target beaten)' : ''} · best ${((career.bestTimes[TRACK] || t) / 1000).toFixed(2)}s · cash $${career.cash}`;
  $results.classList.add('open'); }

(async () => {
  try {
    buildWheel();
    const t = await loadTrack(); trackInfo = t.trackInfo;
    aiStarts = t.trackInfo.ai.map(a => a.position).filter(Boolean);
    skyObj = await loadSky(t.trackInfo.skybox);
    const p = t.trackInfo.player ? t.trackInfo.player.position : { x: 0, y: 0, z: 0 };
    const { settings, kit, upgrades, health } = await loadCarData(CAR);
    game.health = game.maxHealth = health;
    if (Array.isArray(settings.camera)) camOffset = new THREE.Vector3(settings.camera[0], settings.camera[1], settings.camera[2]);
    if (settings.fov) camFov = Number(settings.fov);
    if (CAR === 'Apache' || CAR === 'Tank') camOffset = new THREE.Vector3(0, -8, 3);
    carRig = await loadCar(CAR, kit, params.get('skin'));
    carRig.root.position.set(p.x, p.y, p.z + 0.7);
    hudBase = `${t.trackInfo.name} · ${t.tileCount} tiles`;
    camera.position.set(p.x, p.y - 7, p.z + 3);
    sfx = new Sfx(DATA, SOUND);
    fx = new FX(scene, { loadTexture, texDirs: [`${DATA}Shared/Textures/`] }); await fx.init();
    await loadCarVisualAssets();
    await loadCountdown();
    shared = await loadSharedData(fetchText, DATA);
    if (USE_PHYSICS) { say('Loading Rapier…'); try { RAPIER = (await import('@dimforge/rapier3d-compat')).default; await RAPIER.init(); } catch (e) { console.error(e); say('Rapier unavailable – viewer only.'); } }
    if (RAPIER) {
      say('Building collision world…');
      world = await buildWorld(t.tileInstances);
      eventQueue = new RAPIER.EventQueue(true);
      startPose = { x: p.x, y: p.y, z: p.z, yaw: 0 }; checkpoint = { x: p.x, y: p.y, z: p.z, yaw: 0, n: 0 };
      driver = makeDriver(world, carRig, settings, p);
      pose.prev = pose.cur = readPose();
      carVisuals = setupCarVisuals(carRig, CAR, () => driver.body);
      playerRec = { tag: 'Player1', isPlayer: true, name: career.playerName || 'PLAYER', body: driver.body, car: driver.car, collider: driver.collider, visuals: carVisuals, dead: false };
      combat = {
        cars: () => [playerRec, ...(ai ? ai.cars : []), ...[...ghosts.entries()].map(([id, g]) => ghostRec(g, id))],
        byCollider: new Map(),
        damage: (rec, d) => { if (rec.isPlayer) carImpact(d); else if (rec.ghost) { if (net && net.racing) net.sendHit(rec.id, d); } else damageAI(rec, d); }
      };
      combat.byCollider.set(driver.collider.handle, playerRec);
      say('Placing props & pickups…');
      props = new Props({ scene, world, RAPIER, fx, sfx, loadGLB, loadTexture, texDirs: [`${DATA}Shared/Textures/`], shared, trackKey: TRACK,
        onPickup, onScore: s => { game.score += s; },
        onAreaDamage: (pos, data, sender) => { if (weapons) weapons.areaDamage(pos, data, sender); },
        onSync: i => { if (net && net.racing) net.sendProp(i); } });
      await props.init(); props.build(t.tiles, { props: USE_PROPS, pickups: USE_PICKUPS });
      race = new Race({ laps: 1 }); race.build(t.tiles);
      try { const fg = await loadGLB('Finish'); const fin = fg.scene.clone(true);
        const texDirs = [`${DATA}Shared/Textures/`, `${DATA}Tracks/${t.world}/Textures/`];
        const jobs = []; fin.traverse(o => { if (o.isMesh) jobs.push((async () => {
          const tn = o.material.userData && o.material.userData.texture;
          const map = tn ? await firstTexture(tn, texDirs) : null;
          o.material = new THREE.MeshBasicMaterial({ map, color: map ? 0xffffff : baseColor(o.material), side: THREE.DoubleSide, transparent: true, alphaTest: 0.02 });
        })()); });
        await Promise.all(jobs);
        const g = race.finishGate; if (g) { fin.position.copy(g); fin.rotation.z = race.finishYaw; } scene.add(fin); } catch (e) { console.warn('Finish.glb missing', e); }
      if (USE_WEAPONS) { say('Fitting weapons…');
        weapons = new Weapons({ scene, world, RAPIER, fx, sfx, loadGLB, loadTexture, texDirs: [`${DATA}Shared/Textures/`], shared, carRig, driver, carCollider: driver.collider, carName: CAR, upgrades, props, combat, tag: 'Player1',
          onShot: (kind, d) => pushFx(Object.assign({ k: 'shot', kind }, d)),
          onTracer: (mi, o, q, dist, mini) => pushFx({ k: 'tr', mi, o, q, dist, mini: !!mini }),
          onSpark: (p, t) => pushFx({ k: 'spark', p, t }),
          onBoom: (p, d, s, snd) => pushFx({ k: 'boom', p, d, s, snd }) });
        await weapons.init(PRIMARY, SECONDARY); }
      if (!ROOM && AI_COUNT > 0 && t.trackInfo.ai.length) { say('Spawning rivals…');
        try { const ct = await fetchText(`${DATA}Tracks/${t.world}/Data/${t.world}Data.txt`);
          const wp = buildWaypoints(t.tiles, t.world, ct);
          ai = new AI({ scene, world, RAPIER, loadCar, loadCarData, waypoints: wp, starts: t.trackInfo.ai, count: AI_COUNT, getPlayerPos: () => pose.cur ? pose.cur.p : null });
          await ai.init();
          for (const a of ai.cars) {
            a.visuals = setupCarVisuals(a.rig, a.name, () => a.body);
            a.tagSprite = makeNametag(a.name, '#f4c520'); scene.add(a.tagSprite);
            combat.byCollider.set(a.collider.handle, a);
            if (USE_WEAPONS) {
              a.weapons = new Weapons({ scene, world, RAPIER, fx, sfx, loadGLB, loadTexture, texDirs: [`${DATA}Shared/Textures/`], shared, carRig: a.rig, driver: { body: a.body, car: a.car }, carCollider: a.collider, carName: a.name, upgrades: {}, props, combat, tag: a.tag });
              await a.weapons.init('MachineGun', 'RocketPod');
            }
          } } catch (e) { console.warn('AI disabled', e); ai = null; } }
      if (ROOM) { net = new Net(WS); wireNet();
        net.setLoadout({ name: career.playerName || 'Player', car: CAR, primary: PRIMARY, secondary: SECONDARY });
        net.enterRace(ROOM); }
      say('Ready – WASD · Z/X weapons · Shift drift · C reverse · hold G emote · R reset · F free-cam · V debug · M sound · Esc garage.');
      if (AUTOSTART) startRace(); else toggleMenu(true);
      if (START_FLY) setFly(true);
    } else { carRig.root.position.set(p.x, p.y, p.z); say('Viewer only.'); }
    window.__br3 = { scene, camera, renderer, cam, game, career, get driver() { return driver; }, get world() { return world; }, get props() { return props; }, get weapons() { return weapons; }, get race() { return race; }, get ai() { return ai; }, get net() { return net; }, get ghosts() { return ghosts; },
      netDebug: () => ({ id: net && net.id, name: net && net.loadout && net.loadout.name, room: net && net.room && net.room.id, racing: net && net.racing, peers: net ? [...net.peers.keys()] : [], ghosts: [...ghosts.entries()].map(([id, g]) => ({ id, name: g.tagName, dead: g.wasDead, visuals: g.weapons ? g.weapons.visuals.length : 0, debris: g.visuals ? g.visuals.debris.length : 0 })), killCam: game.killCam, fxQueued: fxQueue.length }) };
    hudInfo(); requestAnimationFrame(tick);
  } catch (e) { fail(e); }
})();