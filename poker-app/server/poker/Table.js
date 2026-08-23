const { freshDeck, shuffle } = require('./deck');
const { evaluateBest, compareResults } = require('./handEvaluator');
const { computeSidePots } = require('./potCalculator');

const PHASES = ['waiting', 'preflop', 'flop', 'turn', 'river', 'showdown'];

let tableCounter = 1;

class Table {
  constructor({ name, smallBlind = 10, bigBlind = 20, maxSeats = 6 }) {
    this.id = 'T' + tableCounter++;
    this.name = name || `Table ${this.id}`;
    this.smallBlind = smallBlind;
    this.bigBlind = bigBlind;
    this.maxSeats = maxSeats;
    this.seats = new Array(maxSeats).fill(null);
    this.buttonIndex = -1;
    this.phase = 'waiting';
    this.communityCards = [];
    this.deck = [];
    this.currentBet = 0;
    this.minRaise = bigBlind;
    this.actingIndex = -1;
    this.handNumber = 0;
    this.lastAggressorIndex = -1;
    this.log = [];
    this.pots = []; // computed at showdown/award time
  }

  occupiedSeats() {
    return this.seats
      .map((s, i) => ({ seat: s, i }))
      .filter((x) => x.seat);
  }

  emptySeatIndex() {
    return this.seats.findIndex((s) => s === null);
  }

  sit(seatIndex, player) {
    if (this.seats[seatIndex]) throw new Error('Seat taken');
    this.seats[seatIndex] = {
      userId: player.userId,
      name: player.name,
      cosmetics: player.cosmetics || {},
      stack: player.buyIn,
      holeCards: [],
      folded: false,
      allIn: false,
      bet: 0,
      totalContributed: 0,
      hasActedThisRound: false,
      sittingOut: false,
      lastAction: null,
    };
  }

  leave(seatIndex) {
    const seat = this.seats[seatIndex];
    if (!seat) return null;
    const stack = seat.stack;
    // Mid-hand departures fold the player in place but keep the seat until the hand resolves.
    if (this.phase !== 'waiting' && this.phase !== 'showdown' && seat.holeCards.length) {
      seat.folded = true;
      seat.sittingOut = true;
      seat.leaving = true;
      return null;
    }
    this.seats[seatIndex] = null;
    return stack;
  }

  activePlayerCount() {
    return this.occupiedSeats().filter((x) => !x.seat.sittingOut).length;
  }

  canStartHand() {
    return this.phase === 'waiting' && this.activePlayerCount() >= 2;
  }

  startHand() {
    this.handNumber++;
    this.phase = 'preflop';
    this.communityCards = [];
    this.deck = shuffle(freshDeck());
    this.pots = [];
    this.log = [];

    const occ = this.occupiedSeats().filter((x) => !x.seat.sittingOut && x.seat.stack > 0);
    occ.forEach(({ seat }) => {
      seat.holeCards = [];
      seat.folded = false;
      seat.allIn = false;
      seat.bet = 0;
      seat.totalContributed = 0;
      seat.hasActedThisRound = false;
      seat.lastAction = null;
    });

    // Advance button to next occupied seat.
    const indices = occ.map((x) => x.i);
    if (this.buttonIndex === -1 || !indices.includes(this.buttonIndex)) {
      this.buttonIndex = indices[0];
    } else {
      const pos = indices.indexOf(this.buttonIndex);
      this.buttonIndex = indices[(pos + 1) % indices.length];
    }

    // Deal two hole cards to each active seat.
    for (let round = 0; round < 2; round++) {
      for (const i of this._orderFromButton(indices)) {
        this.seats[i].holeCards.push(this.deck.pop());
      }
    }

    const order = this._orderFromButton(indices);
    if (order.length === 2) {
      // Heads-up: button posts small blind, other posts big blind.
      this._postBlind(order[0], this.smallBlind);
      this._postBlind(order[1], this.bigBlind);
      this.actingIndex = order[0];
    } else {
      this._postBlind(order[1], this.smallBlind);
      this._postBlind(order[2], this.bigBlind);
      this.actingIndex = order[3 % order.length];
    }
    this.currentBet = this.bigBlind;
    this.minRaise = this.bigBlind;
    this.lastAggressorIndex = order.length === 2 ? order[1] : order[2];
    this._clearActedFlags();
    // A short-stacked blind can leave the "next to act" seat already all-in.
    if (!this._seatsThatCanAct().some((x) => x.i === this.actingIndex)) {
      this._advanceActingIndex();
    }
  }

  _postBlind(seatIndex, amount) {
    const seat = this.seats[seatIndex];
    const posted = Math.min(amount, seat.stack);
    seat.stack -= posted;
    seat.bet += posted;
    seat.totalContributed += posted;
    if (seat.stack === 0) seat.allIn = true;
  }

  _orderFromButton(indices) {
    const pos = indices.indexOf(this.buttonIndex);
    return indices.slice(pos).concat(indices.slice(0, pos));
  }

  // First live seat strictly clockwise of the button — correct even if the
  // button's own seat has since folded out of the hand.
  _firstToActAfterButton(liveIndices) {
    const sorted = [...liveIndices].sort((a, b) => a - b);
    let pos = sorted.findIndex((i) => i > this.buttonIndex);
    if (pos === -1) pos = 0;
    return sorted[pos];
  }

  _clearActedFlags() {
    for (const seat of this.seats) {
      if (seat) seat.hasActedThisRound = false;
    }
  }

  _liveSeats() {
    return this.occupiedSeats().filter((x) => !x.seat.folded);
  }

  _seatsThatCanAct() {
    return this.occupiedSeats().filter(
      (x) => !x.seat.folded && !x.seat.allIn && x.seat.stack >= 0 && !x.seat.sittingOut
    );
  }

  legalActions(seatIndex) {
    const seat = this.seats[seatIndex];
    if (!seat || seat.folded || seat.allIn) return [];
    const toCall = this.currentBet - seat.bet;
    const actions = [];
    if (toCall <= 0) {
      actions.push('check');
    } else {
      actions.push('call');
    }
    actions.push('fold');
    if (seat.stack > toCall) {
      actions.push(this.currentBet === 0 ? 'bet' : 'raise');
    }
    actions.push('allin');
    return actions;
  }

  handleAction(seatIndex, action, amount = 0) {
    if (seatIndex !== this.actingIndex) throw new Error('Not your turn');
    const seat = this.seats[seatIndex];
    if (!seat || seat.folded || seat.allIn) throw new Error('Cannot act');
    const toCall = this.currentBet - seat.bet;

    switch (action) {
      case 'fold':
        seat.folded = true;
        seat.lastAction = 'fold';
        break;
      case 'check':
        if (toCall > 0) throw new Error('Cannot check, must call or fold');
        seat.lastAction = 'check';
        break;
      case 'call': {
        const pay = Math.min(toCall, seat.stack);
        seat.stack -= pay;
        seat.bet += pay;
        seat.totalContributed += pay;
        if (seat.stack === 0) seat.allIn = true;
        seat.lastAction = 'call';
        break;
      }
      case 'bet':
      case 'raise': {
        const target = Math.max(amount, this.currentBet + this.minRaise);
        const total = Math.min(target - seat.bet, seat.stack);
        if (total <= 0) throw new Error('Invalid raise size');
        const raiseSize = seat.bet + total - this.currentBet;
        seat.stack -= total;
        seat.bet += total;
        seat.totalContributed += total;
        if (seat.stack === 0) seat.allIn = true;
        if (seat.bet > this.currentBet) {
          this.minRaise = Math.max(this.minRaise, raiseSize);
          this.currentBet = seat.bet;
          this.lastAggressorIndex = seatIndex;
          this._clearActedFlags();
        }
        seat.lastAction = seat.allIn ? 'all-in' : action;
        break;
      }
      case 'allin': {
        const total = seat.stack;
        seat.stack = 0;
        seat.bet += total;
        seat.totalContributed += total;
        seat.allIn = true;
        if (seat.bet > this.currentBet) {
          this.minRaise = Math.max(this.minRaise, seat.bet - this.currentBet);
          this.currentBet = seat.bet;
          this.lastAggressorIndex = seatIndex;
          this._clearActedFlags();
        }
        seat.lastAction = 'all-in';
        break;
      }
      default:
        throw new Error('Unknown action');
    }
    seat.hasActedThisRound = true;

    if (this._liveSeats().length === 1) {
      this._awardUncontested();
      return { handOver: true };
    }

    if (this._isRoundComplete()) {
      return this._advancePhase();
    }
    this._advanceActingIndex();
    return { handOver: false };
  }

  _isRoundComplete() {
    const acting = this._seatsThatCanAct();
    if (acting.length === 0) return true;
    return acting.every((x) => x.seat.hasActedThisRound && x.seat.bet === this.currentBet);
  }

  _advanceActingIndex() {
    const acting = this._seatsThatCanAct().map((x) => x.i);
    if (acting.length === 0) return;
    let idx = (this.actingIndex + 1) % this.maxSeats;
    for (let step = 0; step < this.maxSeats; step++) {
      if (acting.includes(idx)) {
        this.actingIndex = idx;
        return;
      }
      idx = (idx + 1) % this.maxSeats;
    }
  }

  _advancePhase() {
    for (const seat of this.seats) {
      if (seat) seat.bet = 0;
    }
    this._clearActedFlags();

    const stillDeciding = this._seatsThatCanAct().length;
    if (this.phase === 'river' || (stillDeciding <= 1 && this._liveSeats().length > 1)) {
      // Run remaining streets automatically when action is settled (all-ins).
      while (this.communityCards.length < 5) {
        this._dealCommunity();
      }
      return this._showdown();
    }

    if (this.phase === 'preflop') this.phase = 'flop';
    else if (this.phase === 'flop') this.phase = 'turn';
    else if (this.phase === 'turn') this.phase = 'river';

    this._dealCommunity();
    this.currentBet = 0;
    this.minRaise = this.bigBlind;

    const occ = this._liveSeats().map((x) => x.i);
    this.actingIndex = this._firstToActAfterButton(occ);
    if (!this._seatsThatCanAct().some((x) => x.i === this.actingIndex)) {
      this._advanceActingIndex();
    }
    return { handOver: false };
  }

  _dealCommunity() {
    if (this.communityCards.length === 0) {
      this.deck.pop(); // burn
      this.communityCards.push(this.deck.pop(), this.deck.pop(), this.deck.pop());
    } else {
      this.deck.pop(); // burn
      this.communityCards.push(this.deck.pop());
    }
  }

  _awardUncontested() {
    const winner = this._liveSeats()[0];
    const total = this.occupiedSeats().reduce((sum, x) => sum + x.seat.totalContributed, 0);
    winner.seat.stack += total;
    this.phase = 'showdown';
    this.pots = [{ amount: total, eligible: [winner.i], winners: [winner.i] }];
    this.log.push(`${winner.seat.name} wins ${total} chips (everyone else folded)`);
  }

  _showdown() {
    this.phase = 'showdown';
    const entries = this.occupiedSeats().map((x) => ({
      seatIndex: x.i,
      amount: x.seat.totalContributed,
      folded: x.seat.folded,
    }));
    const pots = computeSidePots(entries);

    const results = new Map();
    for (const x of this._liveSeats()) {
      results.set(x.i, evaluateBest([...x.seat.holeCards, ...this.communityCards]));
    }

    for (const pot of pots) {
      const contenders = pot.eligible.filter((i) => results.has(i));
      let best = null;
      let winners = [];
      for (const i of contenders) {
        const r = results.get(i);
        if (!best || compareResults(r, best) > 0) {
          best = r;
          winners = [i];
        } else if (compareResults(r, best) === 0) {
          winners.push(i);
        }
      }
      const share = Math.floor(pot.amount / winners.length);
      let remainder = pot.amount - share * winners.length;
      winners.forEach((i, idx) => {
        this.seats[i].stack += share + (idx < remainder ? 1 : 0);
      });
      pot.winners = winners;
      pot.handName = best ? best.name : null;
    }
    this.pots = pots;
    this.log.push('Showdown complete');
    return { handOver: true, showdown: true, results: Object.fromEntries(results) };
  }

  finishHandCleanup() {
    // Remove players who left mid-hand and busted players below the felt.
    for (let i = 0; i < this.seats.length; i++) {
      const seat = this.seats[i];
      if (seat && seat.leaving) this.seats[i] = null;
    }
    this.phase = 'waiting';
    this.communityCards = [];
    this.currentBet = 0;
  }

  publicState(forSeatIndex = -1) {
    const totalPot = this.occupiedSeats().reduce((sum, x) => sum + x.seat.totalContributed, 0);
    return {
      id: this.id,
      name: this.name,
      smallBlind: this.smallBlind,
      bigBlind: this.bigBlind,
      maxSeats: this.maxSeats,
      phase: this.phase,
      buttonIndex: this.buttonIndex,
      actingIndex: this.actingIndex,
      currentBet: this.currentBet,
      minRaise: this.minRaise,
      communityCards: this.communityCards,
      totalPot,
      pots: this.pots,
      handNumber: this.handNumber,
      log: this.log,
      seats: this.seats.map((seat, i) => {
        if (!seat) return null;
        const showCards =
          seat.holeCards.length > 0 &&
          (i === forSeatIndex || this.phase === 'showdown') &&
          !(this.phase === 'showdown' && seat.folded);
        return {
          userId: seat.userId,
          name: seat.name,
          cosmetics: seat.cosmetics,
          stack: seat.stack,
          bet: seat.bet,
          folded: seat.folded,
          allIn: seat.allIn,
          sittingOut: seat.sittingOut,
          lastAction: seat.lastAction,
          holeCards: showCards ? seat.holeCards : seat.holeCards.length ? ['back', 'back'] : [],
        };
      }),
    };
  }
}

module.exports = { Table, PHASES };
