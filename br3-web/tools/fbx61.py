"""Minimal parser for ASCII FBX 6.1 files (as written by the LingoDecompiler W3D->FBX exporter)."""
import re, sys

KEY = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_ ]*?):\s*(.*)$')

def split_vals(s):
    """Split a value list on commas, honoring quoted strings. Returns python values."""
    out, cur, inq = [], [], False
    for ch in s:
        if ch == '"':
            inq = not inq
            cur.append(ch)
        elif ch == ',' and not inq:
            out.append(''.join(cur).strip()); cur = []
        else:
            cur.append(ch)
    tail = ''.join(cur).strip()
    if tail != '' or out:
        out.append(tail)
    vals = []
    for v in out:
        if v.startswith('"') and v.endswith('"'):
            vals.append(v[1:-1])
        else:
            try:
                vals.append(float(v) if ('.' in v or 'e' in v.lower()) else int(v))
            except ValueError:
                vals.append(v)
    return vals

class Node:
    __slots__ = ('name', 'vals', 'children')
    def __init__(self, name, vals):
        self.name, self.vals, self.children = name, vals, []
    def get(self, name):
        for c in self.children:
            if c.name == name: return c
        return None
    def all(self, name):
        return [c for c in self.children if c.name == name]

def parse(path):
    # join continuation lines (array data wrapped over several lines)
    logical = []
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for raw in f:
            line = raw.rstrip('\r\n')
            st = line.strip()
            if not st or st.startswith(';'):
                continue
            if st == '}' or KEY.match(line):
                logical.append(line)
            elif logical:
                logical[-1] += st
    root = Node('ROOT', [])
    stack = [root]
    for line in logical:
        st = line.strip()
        if st == '}':
            stack.pop(); continue
        m = KEY.match(line)
        name, rest = m.group(1), m.group(2).strip()
        opens = rest.endswith('{')
        if opens: rest = rest[:-1].strip()
        node = Node(name, split_vals(rest) if rest else [])
        stack[-1].children.append(node)
        if opens: stack.append(node)
    return root

if __name__ == '__main__':
    r = parse(sys.argv[1])
    for c in r.children: print(c.name, len(c.children))
