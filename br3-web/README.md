# BR3 web port – milestone 2 (drivable car)

Builds **CityTrack1** from the game's own data files, puts the player's **BMW** (with its bodykit and rims) on the
start line and lets you drive it. The driving code is a port of the original `[PS] Advanced Car` script: a hover car
with four ground rays, spring/damper impulses, grip and steering impulses, run at the original's 32 game frames per
second with 4 physics sub-steps (gravity -39.24). Physics is [Rapier](https://rapier.rs/) instead of Havok.

## Run it
1. Put this `br3-web` folder **inside** your `br3-src` folder (next to `Data/`).
2. In `br3-src`, start a local web server: `python -m http.server 8000`
3. Open http://localhost:8000/br3-web/

three.js and Rapier are loaded (pinned versions) from the jsDelivr CDN, so the first load needs internet.
If Rapier can't be loaded the page falls back to the static viewer.

## Controls
W/S or ↑/↓ accelerate/reverse · A/D or ←/→ steer · Shift handbrake (drift) · R reset to last safe spot
F free camera (drag to look, WASD/QE to fly, wheel = speed) · C chase camera · L car lights · G show collision meshes + invisible walls

URL options: `?track=CityTrack2` `?car=BMW&skin=2` `?lightmaps=0` `?lm=1.5` `?fly=1` `?physics=0` `?ld=0.1` (car linear damping)

## Other tracks / cars
`converted/` holds `CityAssets.glb`, `BMW.glb`, `Skyboxes.glb`, `InvisibleWall.glb`. The game's `.fbx` files are FBX 6.1 ASCII,
which three.js can't read, so `tools/` converts them: from `br3-src`, `python br3-web/tools/convert_all.py --only DesertAssets Nissan`
(or `--all`).

## What's ported
- Driving model (hover springs, throttle/brake/reverse, steering, drift grip, drag), wheel spin/steer, body lean
- Solid track geometry exactly as `CreateTile` registers it (everything except "Transparent" and "Waves" meshes), invisible walls per tile direction
- Chase camera with the original follow speeds, offset (0,-5.5,1.55), 82° pitch, fov 55
- Bodykit from `CarsData.txt` (bumpers, spoiler, rims + `Wheels_Texture`), car lights with additive blending

## Not yet / guesses
- Not verified by me in a browser: tell me what looks or feels wrong.
- Havok vs Rapier will differ in feel (damping, collision response); wall/obstacle friction and restitution are guesses.
- No nitro, AI cars, props (pylons, crates...), checkpoints/laps, sound, menus, weapons, damage, car shadow.
- Reset goes back to the last spot you drove on (the original uses AI waypoints, not ported yet).
- Front lights only show with L (the original turns them on in tunnels/darkness; rear lights come on when reversing).

## EDIT: Milestone 3 – props, pickups & weapons
- Props/pickups built from the `#Xxx_Object` / `#Xxx_PickUp` keys in each `CreateTile` (BuildTileObjects /
  BuildTilePickups): world-space positions, the original's y/z-swapped quaternion conversion, PhysicsObjects
  weights/health/score, static trimesh vs dynamic convex hulls, destructibles with chain explosions, GasTank wreck.
- Pickups billboard to the camera and collect within 3.0: Nitro (+45 max speed, 7.5 s, flame models), Repair,
  Cash ±1000/5000, Detonator (tile chain-detonation), HiddenPackage (localStorage), Monkey/Pig.
- Weapons from SharedData stats, mounted on the car's weapon dummies: MachineGun, DualMachineGun, MiniGun,
  DualMiniGun, Laser (primary, Z) · RocketPod, MineDeployer, GrenadeDeployer, GrenadeLauncher (secondary, X).
  Hitscan tracers + muzzle flashes, rocket ribbon trails, bouncing grenades, mines, areaDamage with impulses.
- Car health (200, Personality Default), momentum-based collision damage (update_Damage), wreck kick + respawn
  at checkpoint after 3 s, score HUD, status popups, game SFX from Data/Shared/Audio (M to mute).
- Convert the new assets first: `python br3-web/tools/convert_all.py --only Objects PickUps Weapons Nitro`
- URL: `&primary=… &secondary=… &weapons=0 &props=0 &pickups=0 &sound=0`
- Deliberate deviations (no AI cars yet): mines arm after 1 s and also trigger on the player; grenade-deployer
  toss impulse is an interpretation of an ambiguous Lingo expression; laser beam drawn to full hit distance;
  DualMiniGun shares one rof counter; wreck → respawn instead of the failed-challenge screen.
- Not ported: traffic, AI, FlameThrower/Airstrike/Missile/HomingMissile/BDM/MainGun, damage textures/smoke,
  menus, checkpoints/laps. Explosions approximate [PS] Rocket Explosion (same atlas/lifetimes/growth).