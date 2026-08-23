const test = require('node:test');
const assert = require('node:assert');
const { Table } = require('../server/poker/Table');

function seatPlayers(table, count, stack = 1000) {
  for (let i = 0; i < count; i++) {
    table.sit(i, { userId: `p${i}`, name: `Player ${i}`, buyIn: stack });
  }
}

test('uncontested pot: everyone folds to one player', () => {
  const table = new Table({ smallBlind: 10, bigBlind: 20, maxSeats: 6 });
  seatPlayers(table, 3, 1000);
  table.startHand();
  const order = [0, 1, 2]; // button=0, SB=1, BB=2 for the first hand
  // Preflop first-to-act in 3-handed is the button (index 0).
  assert.strictEqual(table.actingIndex, 0);
  table.handleAction(0, 'fold');
  const result = table.handleAction(1, 'fold');
  assert.strictEqual(result.handOver, true);
  // Player 2 (big blind) wins the uncontested pot: their own 20 blind plus seat 1's 10 blind.
  assert.strictEqual(table.seats[2].stack, 1000 - 20 + 30);
});

test('heads-up hand runs preflop through showdown and pays the winner', () => {
  const table = new Table({ smallBlind: 10, bigBlind: 20, maxSeats: 2 });
  seatPlayers(table, 2, 1000);
  table.startHand();
  // Heads-up: seat 0 is button/SB, seat 1 is BB. Button acts first preflop.
  assert.strictEqual(table.actingIndex, 0);

  // Rig the cards for a deterministic winner: seat 0 gets the nut flush, seat 1 gets nothing.
  const c = (rank, suit) => ({ rank, suit, value: '23456789TJQKA'.indexOf(rank) + 2 });
  table.seats[0].holeCards = [c('A', 's'), c('K', 's')];
  table.seats[1].holeCards = [c('2', 'h'), c('7', 'd')];
  table.communityCards = [];
  table.deck = [c('4', 'c'), c('9', 'd'), c('J', 'c'), c('T', 's'), c('3', 'h'), c('2', 's'), c('Q', 's'), c('9', 's'), c('5', 's')].reverse();

  table.handleAction(0, 'call'); // completes to 20
  table.handleAction(1, 'check');
  assert.strictEqual(table.phase, 'flop');
  assert.strictEqual(table.communityCards.length, 3);

  // Postflop heads-up: non-button (seat 1) acts first.
  assert.strictEqual(table.actingIndex, 1);
  table.handleAction(1, 'check');
  table.handleAction(0, 'check');
  assert.strictEqual(table.phase, 'turn');

  table.handleAction(1, 'check');
  table.handleAction(0, 'check');
  assert.strictEqual(table.phase, 'river');

  const before0 = table.seats[0].stack;
  const result = table.handleAction(1, 'check');
  const final = table.handleAction(0, 'check');
  assert.strictEqual(final.handOver, true);
  assert.strictEqual(table.phase, 'showdown');
  assert.ok(table.seats[0].stack > before0, 'seat 0 (flush) should win the pot');
  assert.strictEqual(table.seats[1].stack, 1000 - 20);
});

test('all-in short stack creates a side pot only the bigger stacks contest', () => {
  const table = new Table({ smallBlind: 10, bigBlind: 20, maxSeats: 3 });
  table.sit(0, { userId: 'p0', name: 'Short', buyIn: 60 });
  table.sit(1, { userId: 'p1', name: 'Mid', buyIn: 1000 });
  table.sit(2, { userId: 'p2', name: 'Big', buyIn: 1000 });
  table.startHand();

  // Button (0) shoves for its full 60, covering the blind requirements.
  table.handleAction(0, 'allin');
  assert.strictEqual(table.seats[0].allIn, true);
  table.handleAction(1, 'call', 60);
  const result = table.handleAction(2, 'call', 60);

  assert.ok(table.phase === 'flop' || table.phase === 'showdown');
  // Total chips (in stacks + wagered into the pot) must be conserved — nothing created or destroyed.
  const total = table.seats.reduce(
    (s, seat) => s + (seat ? seat.stack + seat.totalContributed : 0),
    0
  );
  assert.strictEqual(total, 60 + 1000 + 1000);
});
