#!/usr/bin/env python3
"""
Convert the game's FBX 6.1 exports to .glb files the browser port can load.

    python tools/convert_all.py            # everything the game needs (all worlds, cars, traffic, props, weapons, UI)
    python tools/convert_all.py --only DesertAssets SnowAssets
    python tools/convert_all.py --all      # every .fbx under Data/
    python tools/convert_all.py --data ../Data --out converted

Output files are flat: <fbx basename>.glb in --out. Duplicate basenames are skipped (reported).
"""
import argparse, glob, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from fbx61_to_glb import convert

WORLD_ASSETS = ['CityAssets', 'DesertAssets', 'JungleAssets', 'SnowAssets']
CARS = ['BMW', 'AstonMartin', 'AudiR8', 'Corvette', 'DodgeRam', 'FordGT', 'Marcos', 'MiniCooper',
        'Mustang', 'Porsche', 'Seat', 'BlackTruck', 'Tank', 'Apache', 'Eclipse', 'Nissan']
TRAFFIC = ['Lupo', 'Transporter', 'Bus', 'Truck']
SHARED = ['Skyboxes', 'InvisibleWall', 'Objects', 'PickUps', 'Weapons', 'Nitro', 'Finish', '1PlayerInterface']
DEFAULT = WORLD_ASSETS + SHARED + CARS + TRAFFIC

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--data', default=os.path.join(HERE, '..', '..', 'Data'))
    ap.add_argument('--out', default=os.path.join(HERE, '..', 'converted'))
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--only', nargs='*', help='fbx basenames (case-insensitive, without extension)')
    a = ap.parse_args()
    data = os.path.abspath(a.data); out = os.path.abspath(a.out)
    os.makedirs(out, exist_ok=True)
    fbxs = sorted(glob.glob(os.path.join(data, '**', '*.fbx'), recursive=True))
    wanted = None if a.all else {n.lower() for n in (a.only if a.only else DEFAULT)}
    seen = set()
    for f in fbxs:
        base = os.path.splitext(os.path.basename(f))[0]
        if wanted is not None and base.lower() not in wanted: continue
        if base in seen:
            print(f'SKIP duplicate name {base}: {f}'); continue
        seen.add(base)
        tex = [os.path.join(os.path.dirname(os.path.dirname(f)), 'Textures'),
               os.path.join(data, 'Shared', 'Textures'), os.path.join(data, 'Cars', 'SkinTextures')]
        dst = os.path.join(out, base + '.glb')
        t = time.time()
        info = convert(f, dst, tex)
        print(f"{base}: {info['meshes']} meshes, {info['bytes']/1e6:.1f} MB, {time.time()-t:.0f}s"
              + (f"  (no PNG for: {', '.join(info['missing_textures'])})" if info['missing_textures'] else ''))
    if wanted is not None:
        miss = wanted - {s.lower() for s in seen}
        if miss: print('NOT FOUND under', data, ':', ', '.join(sorted(miss)))

if __name__ == '__main__':
    main()