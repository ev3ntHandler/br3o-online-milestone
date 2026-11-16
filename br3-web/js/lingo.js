// Minimal parser for the Lingo literal syntax used in the game's data/event text files,
// plus a reader for the "Name_Begin ... Name_End" event-file format (see Event Manager.ls).
//
// Lingo values handled: integers/floats, "strings", #symbols, TRUE/FALSE/VOID,
// vector(x,y,z), [list, ...], [#key: value, ...] (property lists) and [:] (empty prop list).
// Anything else (e.g. `gGame.car`, `"Player" & x`) is returned as { expr: "<source text>" }.

export class LingoVector { constructor(x, y, z) { this.x = x; this.y = y; this.z = z; } }
export class LingoSymbol { constructor(name) { this.name = name; } toString() { return '#' + this.name; } }

class Reader {
  constructor(s) { this.s = s; this.i = 0; }
  ws() { while (this.i < this.s.length && /\s/.test(this.s[this.i])) this.i++; }
  peek() { this.ws(); return this.s[this.i]; }
  eof() { this.ws(); return this.i >= this.s.length; }
}

function parseValue(r) {
  const c = r.peek();
  if (c === '[') return parseList(r);
  if (c === '"') return parseString(r);
  if (c === '#') {
    r.i++;
    const m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(r.s.slice(r.i));
    r.i += m[0].length;
    return new LingoSymbol(m[0]);
  }
  const rest = r.s.slice(r.i);
  let m = /^-?\d+(\.\d+)?([eE][-+]?\d+)?/.exec(rest);
  if (m) { r.i += m[0].length; return Number(m[0]); }
  m = /^vector\s*\(/i.exec(rest);
  if (m) {
    r.i += m[0].length;
    const nums = [];
    for (let k = 0; k < 3; k++) {
      nums.push(parseValue(r));
      if (r.peek() === ',') r.i++;
    }
    if (r.peek() === ')') r.i++;
    return new LingoVector(nums[0], nums[1], nums[2]);
  }
  m = /^(TRUE|FALSE|VOID)\b/i.exec(rest);
  if (m) {
    r.i += m[0].length;
    const k = m[0].toUpperCase();
    return k === 'TRUE' ? true : k === 'FALSE' ? false : null;
  }
  // unknown expression: read up to the next top-level , ] or )
  let depth = 0, start = r.i;
  while (r.i < r.s.length) {
    const ch = r.s[r.i];
    if (ch === '"') { parseString(r); continue; }
    if (ch === '(' || ch === '[') depth++;
    else if (ch === ')' || ch === ']') { if (depth === 0) break; depth--; }
    else if (ch === ',' && depth === 0) break;
    r.i++;
  }
  return { expr: r.s.slice(start, r.i).trim() };
}

function parseString(r) {
  r.ws();
  r.i++; // opening quote
  let out = '';
  while (r.i < r.s.length && r.s[r.i] !== '"') out += r.s[r.i++];
  r.i++;
  return out;
}

function parseList(r) {
  r.i++; // [
  r.ws();
  if (r.s[r.i] === ':' ) { r.i++; r.ws(); if (r.s[r.i] === ']') r.i++; return {}; }   // [:]
  const items = [];
  let isProps = false;
  const props = {};
  while (!r.eof() && r.peek() !== ']') {
    const save = r.i;
    const v = parseValue(r);
    if (v instanceof LingoSymbol && r.peek() === ':') {        // #key: value
      r.i++;
      isProps = true;
      props[v.name] = parseValue(r);
    } else {
      items.push(v);
    }
    if (r.peek() === ',') r.i++;
    if (r.i === save) r.i++; // safety: always advance
  }
  r.i++; // ]
  return isProps ? props : items;
}

export function parseLingo(text) {
  const r = new Reader(text);
  return parseValue(r);
}

// ---- event / data file reader -------------------------------------------------------------
// Returns { blocks: { BlockName: [ { cmd, fields: [...raw strings] } ] }, order: [BlockName...] }
export function parseEventsFile(text) {
  const blocks = {}, order = [];
  let cur = null;
  for (const raw of text.split(/\r?\n/)) {
    if (!raw.trim() || raw.startsWith('//') || raw.startsWith('--')) continue;
    const line = raw.replace(/\s+$/, '');
    const mb = /^([A-Za-z0-9_]+)_Begin\s*$/.exec(line);
    if (mb) { cur = mb[1]; blocks[cur] = []; order.push(cur); continue; }
    if (/^[A-Za-z0-9_]+_End\s*$/.test(line)) { cur = null; continue; }
    if (cur === null) continue;
    const parts = line.trim().split('\t');
    blocks[cur].push({ cmd: parts[0], fields: parts.slice(1) });
  }
  return { blocks, order };
}

// Convert a Lingo value tree into plain JS (vectors -> {x,y,z}, symbols -> strings)
export function plain(v) {
  if (v instanceof LingoVector) return { x: v.x, y: v.y, z: v.z };
  if (v instanceof LingoSymbol) return v.name;
  if (Array.isArray(v)) return v.map(plain);
  if (v && typeof v === 'object' && !('expr' in v)) {
    const o = {}; for (const k of Object.keys(v)) o[k] = plain(v[k]); return o;
  }
  return v;
}
