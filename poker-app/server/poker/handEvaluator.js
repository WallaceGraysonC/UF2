// Evaluates the best 5-card poker hand out of any N (>=5) cards.
// Returns { category, tiebreak, best5 } where higher category/tiebreak wins.
// category: 8 straight flush, 7 quads, 6 full house, 5 flush, 4 straight,
//           3 trips, 2 two pair, 1 pair, 0 high card.

const CATEGORY_NAMES = [
  'High Card', 'Pair', 'Two Pair', 'Three of a Kind', 'Straight',
  'Flush', 'Full House', 'Four of a Kind', 'Straight Flush',
];

function combinations(arr, k) {
  const results = [];
  const combo = [];
  function recurse(start) {
    if (combo.length === k) {
      results.push(combo.slice());
      return;
    }
    for (let i = start; i < arr.length; i++) {
      combo.push(arr[i]);
      recurse(i + 1);
      combo.pop();
    }
  }
  recurse(0);
  return results;
}

function evaluate5(cards) {
  const values = cards.map((c) => c.value).sort((a, b) => b - a);
  const suits = cards.map((c) => c.suit);
  const isFlush = suits.every((s) => s === suits[0]);

  const counts = new Map();
  for (const v of values) counts.set(v, (counts.get(v) || 0) + 1);
  const groups = [...counts.entries()].sort((a, b) => {
    if (b[1] !== a[1]) return b[1] - a[1];
    return b[0] - a[0];
  });

  const uniqueDesc = [...new Set(values)];
  let straightHigh = null;
  if (uniqueDesc.length === 5) {
    if (uniqueDesc[0] - uniqueDesc[4] === 4) {
      straightHigh = uniqueDesc[0];
    } else if (uniqueDesc.join(',') === '14,5,4,3,2') {
      straightHigh = 5; // wheel: A-2-3-4-5
    }
  }

  if (straightHigh && isFlush) {
    return { category: 8, tiebreak: [straightHigh], name: 'Straight Flush' };
  }
  if (groups[0][1] === 4) {
    const kicker = groups.find((g) => g[1] === 1)[0];
    return { category: 7, tiebreak: [groups[0][0], kicker], name: 'Four of a Kind' };
  }
  if (groups[0][1] === 3 && groups[1] && groups[1][1] >= 2) {
    return { category: 6, tiebreak: [groups[0][0], groups[1][0]], name: 'Full House' };
  }
  if (isFlush) {
    return { category: 5, tiebreak: values, name: 'Flush' };
  }
  if (straightHigh) {
    return { category: 4, tiebreak: [straightHigh], name: 'Straight' };
  }
  if (groups[0][1] === 3) {
    const kickers = groups.filter((g) => g[1] === 1).map((g) => g[0]).sort((a, b) => b - a);
    return { category: 3, tiebreak: [groups[0][0], ...kickers], name: 'Three of a Kind' };
  }
  if (groups[0][1] === 2 && groups[1] && groups[1][1] === 2) {
    const pairs = [groups[0][0], groups[1][0]].sort((a, b) => b - a);
    const kicker = groups.find((g) => g[1] === 1)[0];
    return { category: 2, tiebreak: [...pairs, kicker], name: 'Two Pair' };
  }
  if (groups[0][1] === 2) {
    const kickers = groups.filter((g) => g[1] === 1).map((g) => g[0]).sort((a, b) => b - a);
    return { category: 1, tiebreak: [groups[0][0], ...kickers], name: 'Pair' };
  }
  return { category: 0, tiebreak: values, name: 'High Card' };
}

function compareResults(a, b) {
  if (a.category !== b.category) return a.category - b.category;
  for (let i = 0; i < Math.max(a.tiebreak.length, b.tiebreak.length); i++) {
    const av = a.tiebreak[i] || 0;
    const bv = b.tiebreak[i] || 0;
    if (av !== bv) return av - bv;
  }
  return 0;
}

// cards: array of >=5 card objects {rank, suit, value}
function evaluateBest(cards) {
  if (cards.length === 5) return { ...evaluate5(cards), cards };
  let best = null;
  for (const combo of combinations(cards, 5)) {
    const result = evaluate5(combo);
    if (!best || compareResults(result, best) > 0) {
      best = { ...result, cards: combo };
    }
  }
  return best;
}

module.exports = { evaluateBest, compareResults, CATEGORY_NAMES };
