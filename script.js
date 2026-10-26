
const button = document.querySelector("#button-clicker");
const scoreDisplay = document.querySelector("#score");
const timerDisplay = document.querySelector("#timer");
const message = document.querySelector("#message");
const usernameInput = document.querySelector("#username");
const leaderboardList = document.querySelector("#leaderboard-list");
const leaderboardMessage = document.querySelector("#leaderboard-message");

const API_URL = "http://localhost:3000";

let score = 0;
let timeLeft = 5;
let gameStarted = false;
let timerId = null;

button.addEventListener("click", () => {
  if (!gameStarted) {
    if (!usernameInput.value.trim()) {
      message.textContent = "Entre ton pseudo avant de commencer !";
      usernameInput.focus();
      return;
    }

    startGame();
    return;
  }

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

  timerId = setInterval(() => {
    timeLeft--;
    timerDisplay.textContent = timeLeft;

    if (timeLeft <= 0) {
      endGame();
    }
  }, 1000);
}

async function endGame() {
  clearInterval(timerId);
  timerId = null;
  gameStarted = false;

  button.disabled = true;
  button.textContent = "Partie terminée";
  message.textContent = `Temps écoulé ! Ton score : ${score} clics. Enregistrement...`;

  try {
    const response = await fetch(`${API_URL}/scores`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        username: usernameInput.value.trim(),
        score: score,
      }),
    });

    if (!response.ok) {
      throw new Error(`Erreur HTTP ${response.status}`);
    }

    message.textContent = `Score de ${score} clics enregistré !`;
  } catch (error) {
    console.error("Erreur d'enregistrement :", error);
    message.textContent =
      `Partie terminée : ${score} clics. Impossible d'enregistrer le score, mais tu peux continuer à jouer.`;
  }

  await loadLeaderboard();

  setTimeout(() => {
    button.disabled = false;
    button.textContent = "Rejouer";
    if (message.textContent.startsWith("Score de")) {
      message.textContent = "Prêt pour une nouvelle partie ?";
    }
  }, 1500);
}

async function loadLeaderboard() {
  try {
    const response = await fetch(`${API_URL}/scores`);

    if (!response.ok) {
      throw new Error(`Erreur HTTP ${response.status}`);
    }

    const scores = await response.json();

    leaderboardList.replaceChildren();

    if (scores.length === 0) {
      leaderboardMessage.textContent = "Aucun score enregistré pour le moment.";
      return;
    }

    leaderboardMessage.textContent = "Les 10 meilleurs scores";

    scores.forEach((entry) => {
      const item = document.createElement("li");
      item.textContent = `${entry.username} — ${entry.score} clics`;
      leaderboardList.appendChild(item);
    });
  } catch (error) {
    console.error("Erreur de chargement du classement :", error);
    leaderboardMessage.textContent =
      "Classement indisponible pour le moment.";
  }
}

loadLeaderboard();
