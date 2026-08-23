# Hold'em

A free, ad-free, multiplayer Texas Hold'em you can play forever.

## What this is (and isn't)

- **No ads, no interstitials, no pop-ups.** There's nothing in the codebase that shows one — no ad SDK, no dialogs you didn't trigger.
- **No in-game purchases, anywhere.** There is no payment integration in this project. Chips cannot be bought with real money — full stop.
- **Play with others without limits.** Any number of hands, any number of tables, no energy/lives system, no cooldowns gating how much you can play.
- **Chips are for show.** The in-game currency only exists to sit at tables and to buy cosmetics (card backs, table felts, avatar colors) in the shop. If you bust out, the game tops you up for free so you're never locked out.

## Running it

```
npm install
npm start
```

Then open `http://localhost:3000`. Register a username/password (stored locally, hashed — no email, no third party).

## Architecture

- `server/index.js` — Express app + Socket.IO server, session-based auth (`/api/register`, `/api/login`, `/api/me`).
- `server/db.js` — tiny JSON-file datastore for accounts, chip balances, and owned/equipped cosmetics. No native dependencies, so it runs anywhere Node runs.
- `server/poker/` — the game engine:
  - `deck.js` — shuffling.
  - `handEvaluator.js` — best 5-of-7 card hand ranking.
  - `potCalculator.js` — main pot / side pot splitting for all-in situations.
  - `Table.js` — the betting round state machine (blinds, turn order, streets, showdown).
  - `GameManager.js` — owns all tables, buy-ins, and hand settlement.
- `server/sockets.js` — real-time events: lobby list, sitting down, in-hand actions, shop purchases.
- `public/` — plain HTML/CSS/JS client (no build step).

## Tests

```
npm test
```

Unit tests cover hand ranking (straights, flushes, ties, the wheel), side-pot math, and full hands played through the `Table` state machine (uncontested folds, heads-up showdowns, all-in side pots).

## Cosmetics shop

Chips earned at the table can be spent on purely visual items — card backs, table felt colors, avatar colors. Nothing purchased there affects gameplay (no stat boosts, no odds changes, no pay-to-win). The shop has no way to accept real money.
