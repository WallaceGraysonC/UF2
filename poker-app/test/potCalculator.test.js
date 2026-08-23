const test = require('node:test');
const assert = require('node:assert');
const { computeSidePots } = require('../server/poker/potCalculator');

test('even contributions with no folds form a single main pot', () => {
  const pots = computeSidePots([
    { seatIndex: 0, amount: 100, folded: false },
    { seatIndex: 1, amount: 100, folded: false },
    { seatIndex: 2, amount: 100, folded: false },
  ]);
  assert.strictEqual(pots.length, 1);
  assert.strictEqual(pots[0].amount, 300);
  assert.deepStrictEqual(pots[0].eligible.sort(), [0, 1, 2]);
});

test('a short all-in creates a side pot the short stack cannot win', () => {
  const pots = computeSidePots([
    { seatIndex: 0, amount: 50, folded: false }, // all-in for 50
    { seatIndex: 1, amount: 150, folded: false },
    { seatIndex: 2, amount: 150, folded: false },
  ]);
  assert.strictEqual(pots.length, 2);
  assert.strictEqual(pots[0].amount, 150); // 50 * 3
  assert.deepStrictEqual(pots[0].eligible.sort(), [0, 1, 2]);
  assert.strictEqual(pots[1].amount, 200); // (150-50) * 2
  assert.deepStrictEqual(pots[1].eligible.sort(), [1, 2]);
});

test('folded players contribute chips but are not eligible to win them', () => {
  const pots = computeSidePots([
    { seatIndex: 0, amount: 100, folded: true },
    { seatIndex: 1, amount: 100, folded: false },
    { seatIndex: 2, amount: 100, folded: false },
  ]);
  assert.strictEqual(pots.length, 1);
  assert.strictEqual(pots[0].amount, 300);
  assert.deepStrictEqual(pots[0].eligible.sort(), [1, 2]);
});
