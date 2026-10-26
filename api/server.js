const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get("/", (req, res) => {
    res.json({
        message: "Bienvenue sur l'API ClickFast",
       
    });
});

app.listen(PORT, "0.0.0.0", () => {
    console.log(`API ClickFast démarrée sur le port ${PORT}`);
});