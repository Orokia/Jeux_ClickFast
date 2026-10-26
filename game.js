function incrementScore(score) {
  return score + 1;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = { incrementScore };
}