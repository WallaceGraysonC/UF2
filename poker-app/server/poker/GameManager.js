const { Table } = require('./Table');
const db = require('../db');

const MIN_BUYIN_BB = 40; // 40 big blinds minimum, so short-stacking can't grief a table
const MAX_BUYIN_BB = 200;

class GameManager {
  constructor(io) {
    this.io = io;
    this.tables = new Map();
    // A couple of tables are always open so there's never "nowhere to play".
    this.createTable({ name: 'Micro Stakes', smallBlind: 5, bigBlind: 10, maxSeats: 6 });
    this.createTable({ name: 'Main Room', smallBlind: 10, bigBlind: 20, maxSeats: 6 });
    this.createTable({ name: 'High Roller', smallBlind: 50, bigBlind: 100, maxSeats: 9 });
  }

  createTable(opts) {
    const table = new Table(opts);
    this.tables.set(table.id, table);
    return table;
  }

  listTables() {
    return [...this.tables.values()].map((t) => ({
      id: t.id,
      name: t.name,
      smallBlind: t.smallBlind,
      bigBlind: t.bigBlind,
      maxSeats: t.maxSeats,
      players: t.occupiedSeats().length,
      phase: t.phase,
    }));
  }

  getTable(id) {
    return this.tables.get(id);
  }

  buyInRange(table) {
    return { min: table.bigBlind * MIN_BUYIN_BB, max: table.bigBlind * MAX_BUYIN_BB };
  }

  sitDown(tableId, user, seatIndex, requestedBuyIn) {
    const table = this.getTable(tableId);
    if (!table) throw new Error('Table not found');
    if (seatIndex == null) seatIndex = table.emptySeatIndex();
    if (seatIndex < 0 || seatIndex >= table.maxSeats) throw new Error('No open seat');
    if (table.seats[seatIndex]) throw new Error('Seat taken');

    const { min, max } = this.buyInRange(table);
    let buyIn = Math.max(min, Math.min(max, requestedBuyIn || max));
    const account = db.getUser(user.id);
    if (account.balance < min) {
      db.freeTopUp(user.id);
    }
    const fresh = db.getUser(user.id);
    buyIn = Math.min(buyIn, fresh.balance);
    if (buyIn < min) buyIn = fresh.balance; // let them sit short rather than blocking play entirely

    db.adjustBalance(user.id, -buyIn);
    table.sit(seatIndex, {
      userId: user.id,
      name: user.username,
      cosmetics: fresh.equipped,
      buyIn,
    });

    if (table.canStartHand()) {
      this._maybeStartHand(table);
    }
    return { table, seatIndex };
  }

  standUp(tableId, userId) {
    const table = this.getTable(tableId);
    if (!table) return;
    const seatIndex = table.seats.findIndex((s) => s && s.userId === userId);
    if (seatIndex === -1) return;
    const stack = table.leave(seatIndex);
    if (stack != null) {
      db.adjustBalance(userId, stack);
    }
  }

  handleAction(tableId, userId, action, amount) {
    const table = this.getTable(tableId);
    if (!table) throw new Error('Table not found');
    const seatIndex = table.seats.findIndex((s) => s && s.userId === userId);
    if (seatIndex === -1) throw new Error('Not seated');
    const result = table.handleAction(seatIndex, action, amount);
    if (result.handOver) {
      this._settleHand(table);
    }
    return result;
  }

  _settleHand(table) {
    // Pay out bank balances for anyone who left mid-hand or busted to zero.
    for (const seat of table.seats) {
      if (seat && seat.leaving) {
        db.adjustBalance(seat.userId, seat.stack);
      }
    }
    table.finishHandCleanup();
    setTimeout(() => {
      // Top up anyone sitting with nothing left, so nobody is stuck unable to play.
      for (const seat of table.seats) {
        if (seat && seat.stack <= 0 && !seat.sittingOut) {
          db.freeTopUp(seat.userId);
          const acct = db.getUser(seat.userId);
          const { min } = this.buyInRange(table);
          const add = Math.min(min, acct.balance);
          db.adjustBalance(seat.userId, -add);
          seat.stack += add;
        }
      }
      if (table.canStartHand()) this._maybeStartHand(table);
      this.io.to(table.id).emit('table:state', { forSeatIndex: -1 });
    }, 3000);
  }

  _maybeStartHand(table) {
    table.startHand();
  }
}

module.exports = { GameManager };
