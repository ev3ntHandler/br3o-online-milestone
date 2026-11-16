// net.js – room lobby + race sync. Batched FX events (shots/tracers/booms) keep the bus light.
class LocalBus {
  constructor(key, onmsg) {
    this.key = 'br3bus-' + key; this.onmsg = onmsg;
    this.h = e => { if (e.key === this.key && e.newValue) { try { this.onmsg(JSON.parse(e.newValue).m); } catch (err) {} } };
    window.addEventListener('storage', this.h);
  }
  post(m) { try { localStorage.setItem(this.key, JSON.stringify({ n: Math.random(), m })); } catch (err) {} }
  close() { window.removeEventListener('storage', this.h); }
}
export class Net {
  constructor(wsUrl) {
    this.id = Math.random().toString(36).slice(2, 10);
    this.wsUrl = wsUrl || null;
    this.room = null; this.isHost = false; this.racing = false;
    this.rooms = new Map(); this.peers = new Map(); this.known = new Set([this.id]);
    this.loadout = { name: 'Player', car: 'BMW', primary: 'MachineGun', secondary: 'RocketPod' };
    this.onLobby = null; this.onRoom = null; this.onStart = null; this.onState = null; this.onPeerLeave = null;
    this.onEmote = null; this.onHit = null; this.onProp = null; this.onDetonate = null; this.onFx = null;
    this._openLobby();
    setInterval(() => {
      this._sendLobby({ t: 'discover' });
      if (this.room && this.isHost && !this.racing) this._announce();
      if (this.racing) { this._prune(); if (this.peers.size === 0) this.send({ t: 'hello' }); }
    }, 1000);
  }
  _openLobby() {
    if (this.wsUrl) { this.ws = new WebSocket(this.wsUrl); this.ws.onmessage = e => { const m = JSON.parse(e.data); if (m.t === 'roommsg') this._roomMsg(m.m); else this._lobbyMsg(m); }; }
    else this.lobby = new LocalBus('lobby', m => this._lobbyMsg(m));
  }
  _sendLobby(m) { if (this.ws) { if (this.ws.readyState === 1) this.ws.send(JSON.stringify(m)); } else this.lobby.post(m); }
  _lobbyMsg(m) {
    if (m.t === 'room') { this.rooms.set(m.room.id, m.room); this.onLobby && this.onLobby([...this.rooms.values()]); }
    else if (m.t === 'roomclose') { this.rooms.delete(m.id); this.onLobby && this.onLobby([...this.rooms.values()]); }
    else if (m.t === 'discover') { if (this.room && this.isHost && !this.racing) this._announce(); }
  }
  me() { return { id: this.id, ...this.loadout }; }
  setLoadout(l) { this.loadout = { ...this.loadout, ...l }; }
  createRoom(name, track) { this.isHost = true; this.room = { id: this.id, name, track, host: this.id, players: [this.me()] }; this._joinChannel(); this._announce(); this.onRoom && this.onRoom(this.room); }
  joinRoom(room) { this.isHost = false; this.room = room; this._joinChannel(); this.send({ t: 'join', player: this.me() }); }
  enterRace(roomId) { this.room = { id: roomId }; this.racing = true; this._joinChannel(); this.send({ t: 'hello' }); }
  _joinChannel() {
    if (this.ws) { const sub = () => this.ws.send(JSON.stringify({ t: 'sub', room: this.room.id })); if (this.ws.readyState === 1) sub(); else this.ws.onopen = sub; }
    else this.channel = new LocalBus('room-' + this.room.id, m => this._roomMsg(m));
  }
  _announce() { this._sendLobby({ t: 'room', room: this.room }); }
  send(m) { m.from = this.id; if (this.ws) { if (this.ws.readyState === 1) this.ws.send(JSON.stringify({ t: 'roommsg', room: this.room.id, m })); } else this.channel && this.channel.post(m); }
  _roomMsg(m) {
    if (!m || m.from === this.id) return;
    if (m.t === 'hello') { if (!this.known.has(m.from)) { this.known.add(m.from); this.peers.set(m.from, { last: performance.now() }); this.send({ t: 'hello' }); } else this.peers.set(m.from, { ...this.peers.get(m.from), last: performance.now() }); return; }
    if (m.t === 'join') { if (this.isHost) { if (!this.room.players.some(p => p.id === m.player.id)) this.room.players.push(m.player); this._announce(); this.send({ t: 'roster', players: this.room.players }); this.onRoom && this.onRoom(this.room); } }
    else if (m.t === 'roster') { this.room.players = m.players; this.onRoom && this.onRoom(this.room); }
    else if (m.t === 'leave') { this.room.players = (this.room.players || []).filter(p => p.id !== m.from); this.peers.delete(m.from); this.known.delete(m.from); this.onPeerLeave && this.onPeerLeave(m.from); this.onRoom && this.onRoom(this.room); }
    else if (m.t === 'state') { this.peers.set(m.from, { ...m, last: performance.now() }); this.onState && this.onState(m); }
    else if (m.t === 'fx') { this.onFx && this.onFx(m); }
    else if (m.t === 'emote') { this.onEmote && this.onEmote(m); }
    else if (m.t === 'hit') { this.onHit && this.onHit(m); }
    else if (m.t === 'prop') { this.onProp && this.onProp(m); }
    else if (m.t === 'detonate') { this.onDetonate && this.onDetonate(m); }
    else if (m.t === 'start') { this.onStart && this.onStart(m.track, m.room); }
  }
  slotIds() { return [this.id, ...this.peers.keys()].sort(); }
  beginRace() { this.racing = true; this.send({ t: 'start', track: this.room.track, room: this.room.id }); this.onStart && this.onStart(this.room.track, this.room.id); }
  broadcastState(s) { if (this.racing) this.send({ t: 'state', ...s }); }
  sendFx(e) { if (this.racing && e.length) this.send({ t: 'fx', e }); }
  sendEmote(e) { this.send({ t: 'emote', e }); }
  sendHit(to, d) { this.send({ t: 'hit', to, d }); }
  sendProp(i) { this.send({ t: 'prop', i }); }
  sendDetonate(tile) { this.send({ t: 'detonate', tile }); }
  _prune() { const now = performance.now(); for (const [id, p] of this.peers) if (now - p.last > 6000) { this.peers.delete(id); this.onPeerLeave && this.onPeerLeave(id); } }
  leave() { this.send({ t: 'leave' }); if (this.isHost) this._sendLobby({ t: 'roomclose', id: this.room.id }); this.channel && this.channel.close(); this.room = null; this.racing = false; this.peers.clear(); }
}