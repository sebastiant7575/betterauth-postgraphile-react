# Fullstack Notes App

BetterAuth + PostGraphile + React notes app with Google/GitHub SSO and row-level security.

## Architecture

- **3 Docker containers**: Postgres (port 5435), Backend (Express + BetterAuth + PostGraphile, port 4000), Frontend (Vite + React, port 5173)
- BetterAuth manages OAuth sessions via cookies
- PostGraphile reads session on each request, sets `pgSettings` for RLS
- Vite dev server proxies `/api/*` and `/graphql` to backend (same-origin for cookies)
- Database schemas: `public` (BetterAuth tables), `app_public` (app tables exposed via GraphQL)

## Prerequisites

- Docker & Docker Compose
- OAuth credentials for Google and/or GitHub

### OAuth Callback URLs

Register these callback URLs with your OAuth providers:

- **Google**: `http://localhost:4000/api/auth/callback/google`
- **GitHub**: `http://localhost:4000/api/auth/callback/github`

## Setup

1. Copy `.env.example` to `.env` and fill in your OAuth credentials:

```bash
cp .env.example .env
```

2. Start everything:

```bash
docker compose up --build
```

3. Visit `http://localhost:5173`

## Development

- Frontend hot-reloads via Vite (source mounted as volume)
- Backend hot-reloads via tsx watch (source mounted as volume)
- GraphiQL available at `http://localhost:4000/graphiql`

### Database Migrations

SQL lives in `backend/migrations/current.sql`. After making changes:

```bash
docker compose exec backend npx graphile-migrate commit
```

## Project Structure

```
.
├── docker-compose.yml
├── postgres/
│   └── init.sh              # Creates shadow DB + roles
├── backend/
│   ├── src/
│   │   ├── index.ts          # Express server
│   │   ├── auth.ts           # BetterAuth config
│   │   ├── db.ts             # pg Pool
│   │   └── postgraphile.ts   # PostGraphile middleware + pgSettings
│   ├── migrations/
│   │   ├── afterReset.sql     # BetterAuth tables, schema, grants
│   │   └── current.sql        # Notes table + RLS
│   └── .gmrc                 # graphile-migrate config
└── frontend/
    └── src/
        ├── main.tsx
        ├── lib/
        │   ├── auth-client.ts # BetterAuth React client
        │   └── apollo.ts      # Apollo Client
        └── routes/
            ├── __root.tsx     # Root layout + navbar
            ├── index.tsx      # Landing page
            ├── login.tsx      # OAuth login buttons
            └── _authenticated/
                ├── dashboard.tsx  # User profile
                └── notes.tsx      # CRUD notes
```
