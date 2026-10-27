"use strict";

const express = require("express");

const PORT = Number(process.env.PORT || 4000);
const app = express();
app.use(express.json());

app.get("/health", (_req, res) => res.json({ status: "UP" }));

app.post("/notify", (req, res) => {
	console.log(`[notifier] nouveau produit : ${JSON.stringify(req.body)}`);
	res.status(202).json({ received: true });
});

const server = app.listen(PORT, () => {
	console.log(`[notifier] en écoute sur le port ${PORT}`);
});

process.on("SIGTERM", () => server.close(() => process.exit(0)));
