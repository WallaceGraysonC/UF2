// Splits total chips contributed this hand into a main pot and any side pots,
// so an all-in player only ever competes for the chips they could actually match.
// entries: [{ seatIndex, amount, folded }]
// returns: [{ amount, eligible: [seatIndex, ...] }]
function computeSidePots(entries) {
  const active = entries.filter((e) => e.amount > 0);
  const levels = [...new Set(active.map((e) => e.amount))].sort((a, b) => a - b);
  const pots = [];
  let prevLevel = 0;
  for (const level of levels) {
    const contributors = active.filter((e) => e.amount >= level);
    const potAmount = (level - prevLevel) * contributors.length;
    const eligible = contributors.filter((e) => !e.folded).map((e) => e.seatIndex);
    if (potAmount > 0) {
      pots.push({ amount: potAmount, eligible });
    }
    prevLevel = level;
  }
  return pots;
}

module.exports = { computeSidePots };
