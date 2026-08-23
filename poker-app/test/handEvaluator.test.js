const test = require('node:test');
const assert = require('node:assert');
const { evaluateBest, compareResults } = require('../server/poker/handEvaluator');

const c = (str) => ({ rank: str[0], suit: str[1], value: '23456789TJQKA'.indexOf(str[0]) + 2 });

test('recognizes a royal flush as a straight flush', () => {
  const hand = [c('As'), c('Ks'), c('Qs'), c('Js'), c('Ts'), c('2h'), c('3d')];
  const result = evaluateBest(hand);
  assert.strictEqual(result.category, 8);
  assert.strictEqual(result.tiebreak[0], 14);
});

test('wheel straight (A-2-3-4-5) counts ace as low', () => {
  const hand = [c('As'), c('2h'), c('3d'), c('4c'), c('5s'), c('Kd'), c('9h')];
  const result = evaluateBest(hand);
  assert.strictEqual(result.category, 4);
  assert.strictEqual(result.tiebreak[0], 5);
});

test('four of a kind beats a full house', () => {
  const quads = evaluateBest([c('9s'), c('9h'), c('9d'), c('9c'), c('2h'), c('3d'), c('4c')]);
  const boat = evaluateBest([c('Ks'), c('Kh'), c('Kd'), c('2c'), c('2h'), c('3d'), c('4c')]);
  assert.ok(compareResults(quads, boat) > 0);
});

test('full house tiebreak uses trips rank then pair rank', () => {
  const a = evaluateBest([c('3s'), c('3h'), c('3d'), c('9c'), c('9h'), c('2d'), c('4c')]);
  const b = evaluateBest([c('2s'), c('2h'), c('2d'), c('Ac'), c('Ah'), c('9d'), c('4c')]);
  assert.ok(compareResults(a, b) > 0); // trip 3s with pair 9s beats trip 2s with pair aces
});

test('flush beats straight', () => {
  const flush = evaluateBest([c('2s'), c('5s'), c('9s'), c('Js'), c('Ks'), c('3h'), c('4d')]);
  const straight = evaluateBest([c('4h'), c('5d'), c('6c'), c('7s'), c('8h'), c('2c'), c('3d')]);
  assert.ok(compareResults(flush, straight) > 0);
});

test('two pair tiebreak: higher top pair wins regardless of kicker', () => {
  const a = evaluateBest([c('Ks'), c('Kh'), c('2d'), c('2c'), c('9h'), c('4d'), c('3s')]);
  const b = evaluateBest([c('Qs'), c('Qh'), c('Jd'), c('Jc'), c('Ah'), c('4d'), c('3s')]);
  assert.ok(compareResults(a, b) > 0);
});

test('identical hands tie', () => {
  const board = [c('2s'), c('7h'), c('9d'), c('Jc'), c('4h')];
  const a = evaluateBest([c('Ks'), c('3h'), ...board]);
  const b = evaluateBest([c('Kd'), c('3c'), ...board]);
  assert.strictEqual(compareResults(a, b), 0);
});
