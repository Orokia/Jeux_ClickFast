require("dotenv").config();

const express = require("express");
const { Pool } = require("pg");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

const pool = new Pool({
    host: process.env.DB_HOST || "127.0.0.1",
    port: Number(process.env.DB_PORT || 5432),
    database: process.env.DB_NAME || "clickfast",
    user: process.env.DB_USER || "clickfast",
    password: process.env.DB_PASSWORD,
});

app.get("/", (req, res) => {
    res.json({
        message: "Bienvenue sur l'API ClickFast",
        status: "OK",
    });
});

// Enregistrer un score
app.post("/scores", async (req, res) => {
    const { username, score } = req.body;

    if (
        typeof username !== "string" ||
        username.trim().length === 0 ||
        username.trim().length > 50 ||
        !Number.isInteger(score) ||
        score < 0
    ) {
        return res.status(400).json({
            error: "Le nom doit contenir de 1 à 50 caractères et le score doit être un entier positif ou nul.",
        });
    }

    try {
        const result = await pool.query(
            "INSERT INTO scores (username, score) VALUES ($1, $2) RETURNING id, username, score, created_at",
            [username.trim(), score]
        );

        return res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error("Erreur lors de l'enregistrement du score :", error.message);
        return res.status(500).json({
            error: "Impossible d'enregistrer le score.",
        });
    }
});

// Récupérer le classement
app.get("/scores", async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT id, username, score, created_at FROM scores ORDER BY score DESC, created_at ASC LIMIT 10"
        );

        return res.json(result.rows);
    } catch (error) {
        console.error("Erreur lors de la récupération du classement :", error.message);
        return res.status(500).json({
            error: "Impossible de récupérer le classement.",
        });
    }
});

app.listen(PORT, "0.0.0.0", () => {
    console.log(`API ClickFast démarrée sur le port ${PORT}`);
});
