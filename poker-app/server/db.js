// Tiny JSON-file datastore. Avoids native deps (bcrypt/sqlite) so the app
// runs anywhere `node` runs, with zero install-time compilation.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DATA_DIR = path.join(__dirname, '..', 'data');
const DATA_FILE = path.join(DATA_DIR, 'users.json');
const STARTING_BALANCE = 1000;
const FREE_TOPUP = 500;

const COSMETIC_CATALOG = [
  { id: 'back-classic', type: 'cardBack', name: 'Classic Red', price: 0 },
  { id: 'back-royal', type: 'cardBack', name: 'Royal Blue', price: 300 },
  { id: 'back-emerald', type: 'cardBack', name: 'Emerald Weave', price: 300 },
  { id: 'back-gold', type: 'cardBack', name: 'Gold Filigree', price: 750 },
  { id: 'felt-green', type: 'tableFelt', name: 'Classic Green', price: 0 },
  { id: 'felt-midnight', type: 'tableFelt', name: 'Midnight Blue', price: 400 },
  { id: 'felt-crimson', type: 'tableFelt', name: 'Crimson', price: 400 },
  { id: 'felt-charcoal', type: 'tableFelt', name: 'Charcoal', price: 400 },
  { id: 'avatar-1', type: 'avatarColor', name: 'Sunset', price: 150 },
  { id: 'avatar-2', type: 'avatarColor', name: 'Ocean', price: 150 },
  { id: 'avatar-3', type: 'avatarColor', name: 'Violet', price: 150 },
];

function ensureStore() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(DATA_FILE)) fs.writeFileSync(DATA_FILE, JSON.stringify({ users: {} }, null, 2));
}

function load() {
  ensureStore();
  return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
}

function save(state) {
  // Synchronous and immediate: reads always go straight to disk (see load()),
  // so a debounced/async write would let a read right after a write miss it.
  fs.writeFileSync(DATA_FILE, JSON.stringify(state, null, 2));
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return { salt, hash };
}

function verifyPassword(password, salt, hash) {
  const check = crypto.scryptSync(password, salt, 64).toString('hex');
  return crypto.timingSafeEqual(Buffer.from(check, 'hex'), Buffer.from(hash, 'hex'));
}

function createUser(username, password) {
  const state = load();
  const key = username.toLowerCase();
  if (state.users[key]) throw new Error('Username already taken');
  const { salt, hash } = hashPassword(password);
  state.users[key] = {
    id: key,
    username,
    salt,
    hash,
    balance: STARTING_BALANCE,
    owned: ['back-classic', 'felt-green'],
    equipped: { cardBack: 'back-classic', tableFelt: 'felt-green', avatarColor: null },
    createdAt: Date.now(),
  };
  save(state);
  return sanitize(state.users[key]);
}

function verifyLogin(username, password) {
  const state = load();
  const user = state.users[username.toLowerCase()];
  if (!user) return null;
  if (!verifyPassword(password, user.salt, user.hash)) return null;
  return sanitize(user);
}

function getUser(id) {
  const state = load();
  const user = state.users[id];
  return user ? sanitize(user) : null;
}

function sanitize(user) {
  const { salt, hash, ...rest } = user;
  return rest;
}

function adjustBalance(id, delta) {
  const state = load();
  const user = state.users[id];
  if (!user) return null;
  user.balance = Math.max(0, user.balance + delta);
  save(state);
  return sanitize(user);
}

// Free top-up when a player busts. Never tied to any payment: it's how the
// app guarantees you can always keep playing without buying chips.
function freeTopUp(id) {
  const state = load();
  const user = state.users[id];
  if (!user) return null;
  if (user.balance >= 50) return sanitize(user); // only top up when truly broke
  user.balance += FREE_TOPUP;
  save(state);
  return sanitize(user);
}

function purchaseCosmetic(id, cosmeticId) {
  const state = load();
  const user = state.users[id];
  if (!user) throw new Error('No such user');
  const item = COSMETIC_CATALOG.find((c) => c.id === cosmeticId);
  if (!item) throw new Error('No such item');
  if (user.owned.includes(cosmeticId)) throw new Error('Already owned');
  if (user.balance < item.price) throw new Error('Not enough chips');
  user.balance -= item.price;
  user.owned.push(cosmeticId);
  save(state);
  return sanitize(user);
}

function equipCosmetic(id, cosmeticId) {
  const state = load();
  const user = state.users[id];
  if (!user) throw new Error('No such user');
  const item = COSMETIC_CATALOG.find((c) => c.id === cosmeticId);
  if (!item) throw new Error('No such item');
  if (!user.owned.includes(cosmeticId)) throw new Error('Not owned');
  user.equipped[item.type] = cosmeticId;
  save(state);
  return sanitize(user);
}

module.exports = {
  createUser,
  verifyLogin,
  getUser,
  adjustBalance,
  freeTopUp,
  purchaseCosmetic,
  equipCosmetic,
  COSMETIC_CATALOG,
  STARTING_BALANCE,
};
