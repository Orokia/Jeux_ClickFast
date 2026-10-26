const { incrementScore } = require("./game");

describe("Compteur de clics ClickFast", () => {
  test("ajoute un clic au score", () => {
    expect(incrementScore(0)).toBe(1);
  });

  test("incrémente un score déjà existant", () => {
    expect(incrementScore(5)).toBe(6);
  });

  test("gère un score de départ nul", () => {
    expect(incrementScore(0)).toBe(1);
  });
});