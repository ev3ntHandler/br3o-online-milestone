#!/usr/bin/env python3
"""
Convert ASCII FBX 6.1 files written by LingoDecompiler's W3D->FBX exporter into binary glTF (.glb),
which three.js can load. three.js' FBXLoader does not support FBX versions below 7000.

Notes
 - The scene stays Z-up (like Shockwave 3D / the original Lingo scripts). glTF "asset.extras.upAxis" says so.
 - Geometry is written non-indexed (UVs are per polygon-vertex in the source).
 - Every material gets extras.texture = "<Name>_Texture" if a matching PNG exists in --textures.
 - Files whose models are flat but follow the "<Tile>_Root" + "<Tile><Suffix>" naming (track tile sets) are
   re-parented by name, as the original game did at run time.

usage: fbx61_to_glb.py in.fbx out.glb [--textures DIR ...]
"""
import sys, os, json, math, struct, argparse
from collections import defaultdict
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fbx61 import parse

def props(node):
    out = {}
    p = node.get('Properties60')
    if p:
        for c in p.children:
            if c.name == 'Property' and len(c.vals) >= 4:
                out[c.vals[0]] = c.vals[3:]
    return out

def euler_xyz_to_quat(rx, ry, rz):
    """FBX rotation order XYZ (degrees): apply X, then Y, then Z => R = Rz*Ry*Rx. Returns (x,y,z,w)."""
    rx, ry, rz = (math.radians(a) / 2.0 for a in (rx, ry, rz))
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)
    # q = qz * qy * qx
    w = cz*cy*cx + sz*sy*sx
    x = cz*cy*sx - sz*sy*cx
    y = cz*sy*cx + sz*cy*sx
    z = sz*cy*cx - cz*sy*sx
    return (x, y, z, w)

class Builder:
    def __init__(self):
        self.bin = bytearray()
        self.views, self.accessors = [], []
    def add(self, data, comp, count, typ, target=34962, minmax=None):
        while len(self.bin) % 4: self.bin.append(0)
        off = len(self.bin)
        self.bin += data
        self.views.append({'buffer': 0, 'byteOffset': off, 'byteLength': len(data), 'target': target})
        acc = {'bufferView': len(self.views) - 1, 'componentType': comp, 'count': count, 'type': typ}
        if minmax: acc['min'], acc['max'] = minmax
        self.accessors.append(acc)
        return len(self.accessors) - 1

def polygons(pvi):
    poly = []
    for i in pvi:
        if i < 0: poly.append(-i - 1); yield poly; poly = []
        else: poly.append(i)

def layer_data(mesh, kind, arr, idxname=None):
    nodes = mesh.all(kind)
    res = []
    for n in nodes:
        mapping = n.get('MappingInformationType').vals[0]
        ref = n.get('ReferenceInformationType').vals[0]
        data = n.get(arr).vals
        idx = n.get(idxname).vals if idxname and n.get(idxname) else None
        res.append((mapping, ref, data, idx))
    return res

def build_mesh(b, node, materials_index):
    verts = node.get('Vertices').vals
    pvi = node.get('PolygonVertexIndex').vals
    normals = layer_data(node, 'LayerElementNormal', 'Normals')
    uvs = layer_data(node, 'LayerElementUV', 'UV', 'UVIndex')
    matl = node.get('LayerElementMaterial')
    mat_map = matl.get('MappingInformationType').vals[0] if matl else 'AllSame'
    mat_vals = matl.get('Materials').vals if matl and matl.get('Materials') else [0]
    # per-polygon-vertex running counter -> UV lookups
    prims = defaultdict(lambda: {'pos': [], 'nrm': [], 'uv0': [], 'uv1': []})
    pv = 0   # polygon-vertex counter
    for pi, poly in enumerate(polygons(pvi)):
        m = mat_vals[0] if mat_map == 'AllSame' else mat_vals[min(pi, len(mat_vals) - 1)]
        P = prims[m]
        corners = []
        for k, vi in enumerate(poly):
            pos = verts[vi*3:vi*3+3]
            # normal
            nrm = (0.0, 0.0, 1.0)
            if normals:
                mp, ref, data, _ = normals[0]
                j = vi if mp == 'ByVertice' else pv + k
                nrm = data[j*3:j*3+3]
            uv = []
            for (mp, ref, data, idx) in uvs[:2]:
                j = pv + k if mp == 'ByPolygonVertex' else vi
                if ref == 'IndexToDirect' and idx is not None: j = idx[j]
                uv.append((data[j*2], 1.0 - data[j*2+1]))   # glTF/three flipY convention: v' = 1 - v
            corners.append((pos, nrm, uv))
        pv += len(poly)
        for t in range(1, len(corners) - 1):
            for c in (corners[0], corners[t], corners[t+1]):
                P['pos'] += c[0]; P['nrm'] += c[1]
                P['uv0'] += c[2][0] if len(c[2]) > 0 else (0.0, 0.0)
                P['uv1'] += c[2][1] if len(c[2]) > 1 else (0.0, 0.0)
    gl_prims = []
    for m, P in sorted(prims.items()):
        n = len(P['pos']) // 3
        xs, ys, zs = P['pos'][0::3], P['pos'][1::3], P['pos'][2::3]
        attrs = {
            'POSITION': b.add(struct.pack('<%df' % (n*3), *P['pos']), 5126, n, 'VEC3', minmax=([min(xs), min(ys), min(zs)], [max(xs), max(ys), max(zs)])),
            'NORMAL': b.add(struct.pack('<%df' % (n*3), *P['nrm']), 5126, n, 'VEC3'),
        }
        if uvs: attrs['TEXCOORD_0'] = b.add(struct.pack('<%df' % (n*2), *P['uv0']), 5126, n, 'VEC2')
        if len(uvs) > 1: attrs['TEXCOORD_1'] = b.add(struct.pack('<%df' % (n*2), *P['uv1']), 5126, n, 'VEC2')
        gl_prims.append({'attributes': attrs, 'material': materials_index(m)})
    return gl_prims

def convert(src, dst, tex_dirs):
    root = parse(src)
    obj, conn = root.get('Objects'), root.get('Connections')
    models, order = {}, []
    for m in obj.children:
        if m.name == 'Model':
            n = m.vals[0].split('::', 1)[1]
            models[n] = m; order.append(n)
    mats = [m for m in obj.children if m.name == 'Material']
    mat_names = [m.vals[0].split('::', 1)[1] for m in mats]
    parent, model_mats = {}, defaultdict(list)
    for c in conn.children:
        a, bb = c.vals[1], c.vals[2]
        if a.startswith('Model::') and bb.startswith('Model::'): parent[a[7:]] = bb[7:]
        elif a.startswith('Material::') and bb.startswith('Model::'): model_mats[bb[7:]].append(a[10:])
    have_tex = set()
    for d in tex_dirs:
        if os.path.isdir(d): have_tex |= {os.path.splitext(f)[0] for f in os.listdir(d) if f.lower().endswith('.png')}
    gl_materials, mat_lookup = [], {}
    def gl_material(name):
        if name in mat_lookup: return mat_lookup[name]
        src_m = mats[mat_names.index(name)] if name in mat_names else None
        diff = props(src_m).get('DiffuseColor', [1, 1, 1]) if src_m else [1, 1, 1]
        gm = {'name': name, 'pbrMetallicRoughness': {'baseColorFactor': [diff[0], diff[1], diff[2], 1.0], 'metallicFactor': 0.0, 'roughnessFactor': 1.0}, 'doubleSided': True}
        tex = name[:-len('_Material')] + '_Texture' if name.endswith('_Material') else None
        if tex and tex in have_tex: gm['extras'] = {'texture': tex}
        elif tex: gm['extras'] = {'missingTexture': tex}
        gl_materials.append(gm); mat_lookup[name] = len(gl_materials) - 1
        return mat_lookup[name]
    # re-parent flat tile sets by name
    types = [n[:-5] for n in order if n.endswith('_Root')]
    for n in order:
        if n in parent and parent[n] != 'Scene': continue
        if n.endswith('_Root'): continue
        cands = [t for t in types if n.startswith(t) and len(n) > len(t) and (n[len(t)] == '_' or n[len(t)].isupper())]
        if cands: parent[n] = max(cands, key=len) + '_Root'
    b = Builder()
    nodes, index_of, gl_meshes = [], {}, []
    skipped = []
    for n in order:
        m = models[n]; kind = m.vals[1]
        if kind in ('Camera', 'Light') or n in ('Scene', 'UIAmbient'): skipped.append(n); continue
        p = props(m)
        t = p.get('Lcl Translation', [0, 0, 0]); r = p.get('Lcl Rotation', [0, 0, 0]); s = p.get('Lcl Scaling', [1, 1, 1])
        gn = {'name': n, 'extras': {'fbxType': kind}}
        if any(abs(v) > 1e-9 for v in t): gn['translation'] = [t[0], t[1], t[2]]
        if any(abs(v) > 1e-9 for v in r): gn['rotation'] = list(euler_xyz_to_quat(*r))
        if any(abs(v - 1) > 1e-9 for v in s): gn['scale'] = [s[0], s[1], s[2]]
        # skip the 10x10x10 helper box in tile "_Root" nodes and any collision-proxy only when flagged by name
        if kind == 'Mesh' and m.get('Vertices') and not n.endswith('_Root'):
            local = model_mats.get(n, [])
            def mi(i, local=local): return gl_material(local[i] if i < len(local) else 'DefaultMaterial')
            prims = build_mesh(b, m, mi)
            gl_meshes.append({'name': n, 'primitives': prims}); gn['mesh'] = len(gl_meshes) - 1
        index_of[n] = len(nodes); nodes.append(gn)
    scene_nodes = []
    for n in order:
        if n not in index_of: continue
        par = parent.get(n, 'Scene')
        if par in index_of: nodes[index_of[par]].setdefault('children', []).append(index_of[n])
        else: scene_nodes.append(index_of[n])
    gltf = {'asset': {'version': '2.0', 'generator': 'fbx61_to_glb.py', 'extras': {'upAxis': 'Z', 'source': os.path.basename(src)}},
            'scene': 0, 'scenes': [{'nodes': scene_nodes}], 'nodes': nodes, 'meshes': gl_meshes, 'materials': gl_materials,
            'buffers': [{'byteLength': len(b.bin)}], 'bufferViews': b.views, 'accessors': b.accessors}
    js = json.dumps(gltf, separators=(',', ':')).encode()
    while len(js) % 4: js += b' '
    binb = bytes(b.bin)
    while len(binb) % 4: binb += b'\0'
    glb = struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(binb)) + struct.pack('<I4s', len(js), b'JSON') + js + struct.pack('<I4s', len(binb), b'BIN\0') + binb
    with open(dst, 'wb') as f: f.write(glb)
    missing = sorted({g['extras']['missingTexture'] for g in gl_materials if 'extras' in g and 'missingTexture' in g['extras']})
    return {'nodes': len(nodes), 'meshes': len(gl_meshes), 'materials': [g['name'] for g in gl_materials], 'missing_textures': missing, 'bytes': len(glb), 'skipped': skipped}

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('src'); ap.add_argument('dst')
    ap.add_argument('--textures', nargs='*', default=[])
    a = ap.parse_args()
    info = convert(a.src, a.dst, a.textures)
    print(json.dumps(info, indent=1))
