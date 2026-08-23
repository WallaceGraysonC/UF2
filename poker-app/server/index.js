const path = require('path');
const express = require('express');
const session = require('express-session');
const http = require('http');
const { Server } = require('socket.io');

const db = require('./db');
const { GameManager } = require('./poker/GameManager');
const { registerSocketHandlers } = require('./sockets');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const sessionMiddleware = session({
  secret: process.env.SESSION_SECRET || 'holdem-dev-secret-change-me',
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true, sameSite: 'lax', maxAge: 30 * 24 * 60 * 60 * 1000 },
});

app.use(express.json());
app.use(sessionMiddleware);
app.use(express.static(path.join(__dirname, '..', 'public')));
// Share the session with socket.io handshakes so sockets know who's connected.
io.engine.use(sessionMiddleware);

app.post('/api/register', (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password || username.length < 3 || password.length < 4) {
    return res.status(400).json({ error: 'Username (3+) and password (4+) required' });
  }
  if (!/^[a-zA-Z0-9_]+$/.test(username)) {
    return res.status(400).json({ error: 'Username may only contain letters, numbers, underscore' });
  }
  try {
    const user = db.createUser(username, password);
    req.session.userId = user.id;
    res.json({ user });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post('/api/login', (req, res) => {
  const { username, password } = req.body || {};
  const user = db.verifyLogin(username || '', password || '');
  if (!user) return res.status(401).json({ error: 'Invalid username or password' });
  req.session.userId = user.id;
  res.json({ user });
});

app.post('/api/logout', (req, res) => {
  req.session.destroy(() => res.json({ ok: true }));
});

app.get('/api/me', (req, res) => {
  if (!req.session.userId) return res.status(401).json({ error: 'Not logged in' });
  const user = db.getUser(req.session.userId);
  if (!user) return res.status(401).json({ error: 'Not logged in' });
  res.json({ user });
});

app.get('/api/shop', (req, res) => {
  res.json({ catalog: db.COSMETIC_CATALOG });
});

const gameManager = new GameManager(io);
registerSocketHandlers(io, gameManager);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Hold'em server listening on http://localhost:${PORT}`);
});

module.exports = { app, server, io, gameManager };
