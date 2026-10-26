
const button = document.querySelector("#button-clicker");
const scoreDisplay = document.querySelector("#score");
const timerDisplay = document.querySelector("#timer");
const message = document.querySelector("#message");

let score = 0;
let timeLeft = 5;
let gameStarted = false;
let timerId = null;

button.addEventListener("click", () => {
  // Premier clic : démarrage de la partie
  if (!gameStarted) {
    startGame();
    return;
  }

  // Incrémente le score uniquement pendant la partie
  score++;
  scoreDisplay.textContent = score;
});

function startGame() {
  score = 0;
  timeLeft = 5;
  gameStarted = true;

  scoreDisplay.textContent = score;
  timerDisplay.textContent = timeLeft;
  message.textContent = "Vite ! Clique le plus possible !";
  button.textContent = "Clique vite !";
  button.disabled = false;

  // Démarre le chronomètre
  timerId = setInterval(() => {
    timeLeft--;
    timerDisplay.textContent = timeLeft;

    if (timeLeft <= 0) {
      endGame();
    }
  }, 1000);
}

function endGame() {
  clearInterval(timerId);
  timerId = null;
  gameStarted = false;

  button.disabled = true;
  button.textContent = "Partie terminée";
  message.textContent = `Temps écoulé ! Ton score : ${score} clics.`;

  // Autorise une nouvelle partie après la fin
  setTimeout(() => {
    button.disabled = false;
    button.textContent = "Rejouer";
    message.textContent = "Prêt pour une nouvelle partie ?";
  }, 1500);
}

// Le bouton est activé pour pouvoir démarrer la partie
button.disabled = false;
