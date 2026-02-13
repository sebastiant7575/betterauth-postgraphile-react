import express from "express";
import cors from "cors";
import { toNodeHandler } from "better-auth/node";
import { auth } from "./auth.js";
import { postgraphileMiddleware } from "./postgraphile.js";

const app = express();
const PORT = 4000;

// CORS
app.use(
  cors({
    origin: ["http://localhost:5173"],
    credentials: true,
  })
);

// Health check
app.get("/api/health", (_req, res) => {
  res.json({ status: "ok" });
});

// BetterAuth handler — MUST be before express.json()
app.all("/api/auth/*", toNodeHandler(auth));

// JSON parsing for other routes
app.use(express.json());

// PostGraphile
app.use(postgraphileMiddleware);

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Backend running on http://localhost:${PORT}`);
  console.log(`GraphiQL: http://localhost:${PORT}/graphiql`);
});
