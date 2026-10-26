
const js = require("@eslint/js");

module.exports = [
  {
    ignores: [
      "node_modules/**",
      "api/node_modules/**",
      "stats-api/**",
    ],
  },
  {
    files: ["*.js"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "commonjs",
      globals: {
        // Node.js
        require: "readonly",
        module: "readonly",
        process: "readonly",

        // Navigateur
        document: "readonly",
        window: "readonly",
        fetch: "readonly",
        console: "readonly",
        setInterval: "readonly",
        clearInterval: "readonly",
        incrementScore: "readonly",
        setTimeout: "readonly",

        // Jest
        describe: "readonly",
        test: "readonly",
        expect: "readonly",
      },
    },
    rules: {
      ...js.configs.recommended.rules,
    },
  },
];
