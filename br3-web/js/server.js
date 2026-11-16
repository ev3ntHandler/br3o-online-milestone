// server.js – tiny WebSocket relay for cross-browser / cross-machine online rooms.
//   npm install ws
//   node tools/server.js            (listens on :8080)
// then open the game with  ?ws=ws://localhost:8080  (or ws://<host>:8080 on other machines).
const { WebSocketServer } = require('ws');
const wss = new WebSocketServer({ port: 8080 });
const rooms = new Map(); // room -> Set<ws>
wss.on('connection', ws => {
  ws.subs = new Set();
  ws.on('message', buf => {
    let m; try { m = JSON.parse(buf); } catch (e) { return; }
    if (m.t === 'sub') { ws.subs.add(m.room); if (!rooms.has(m.room)) rooms.set(m.room, new Set()); rooms.get(m.room).add(ws); return; }
    if (m.t === 'roommsg') { const set = rooms.get(m.room); if (set) for (const c of set) if (c !== ws && c.readyState === 1) c.send(buf); return; }
    // lobby-level messages broadcast to everyone
    for (const c of wss.clients) if (c !== ws && c.readyState === 1) c.send(buf);
  });
  ws.on('close', () => { for (const r of ws.subs) { const set = rooms.get(r); if (set) set.delete(ws); } });
});
console.log('BR3 relay on :8080');