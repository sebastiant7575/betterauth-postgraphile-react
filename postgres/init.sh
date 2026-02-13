#!/bin/bash
set -e

# Create shadow database for graphile-migrate
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --port "$POSTGRES_PORT" <<-EOSQL
    CREATE DATABASE app_shadow;
EOSQL

# Create roles
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --port "$POSTGRES_PORT" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_postgraphile') THEN
            CREATE ROLE app_postgraphile LOGIN PASSWORD 'postgraphile_pass';
        END IF;
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_authenticated') THEN
            CREATE ROLE app_authenticated;
        END IF;
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_anonymous') THEN
            CREATE ROLE app_anonymous;
        END IF;
    END
    \$\$;

    GRANT app_authenticated TO app_postgraphile;
    GRANT app_anonymous TO app_postgraphile;

    GRANT CONNECT, CREATE ON DATABASE app TO app_postgraphile;
    GRANT CONNECT ON DATABASE app_shadow TO app_postgraphile;
EOSQL

# BetterAuth tables
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --port "$POSTGRES_PORT" <<-EOSQL
    CREATE TABLE IF NOT EXISTS "user" (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        "emailVerified" BOOLEAN NOT NULL DEFAULT FALSE,
        image TEXT,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS session (
        id TEXT PRIMARY KEY,
        "expiresAt" TIMESTAMP NOT NULL,
        token TEXT NOT NULL UNIQUE,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        "ipAddress" TEXT,
        "userAgent" TEXT,
        "userId" TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS account (
        id TEXT PRIMARY KEY,
        "accountId" TEXT NOT NULL,
        "providerId" TEXT NOT NULL,
        "userId" TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
        "accessToken" TEXT,
        "refreshToken" TEXT,
        "idToken" TEXT,
        "accessTokenExpiresAt" TIMESTAMP,
        "refreshTokenExpiresAt" TIMESTAMP,
        scope TEXT,
        password TEXT,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS verification (
        id TEXT PRIMARY KEY,
        identifier TEXT NOT NULL,
        value TEXT NOT NULL,
        "expiresAt" TIMESTAMP NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
    );

    -- Grant read on BetterAuth tables for session lookup
    GRANT SELECT ON "user", session, account, verification TO app_postgraphile;
EOSQL

# App schema + notes table + RLS
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --port "$POSTGRES_PORT" <<-EOSQL
    CREATE SCHEMA IF NOT EXISTS app_public;
    GRANT USAGE ON SCHEMA app_public TO app_postgraphile, app_authenticated, app_anonymous;

    ALTER DEFAULT PRIVILEGES IN SCHEMA app_public
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_authenticated;
    ALTER DEFAULT PRIVILEGES IN SCHEMA app_public
        GRANT SELECT ON TABLES TO app_anonymous;
    ALTER DEFAULT PRIVILEGES IN SCHEMA app_public
        GRANT USAGE, SELECT ON SEQUENCES TO app_authenticated;

    -- Notes table
    CREATE TABLE IF NOT EXISTS app_public.notes (
        id SERIAL PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT current_setting('jwt.claims.user_id', true),
        title TEXT NOT NULL DEFAULT '',
        body TEXT NOT NULL DEFAULT '',
        created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
    );

    COMMENT ON COLUMN app_public.notes.user_id IS E'@omit create,update';

    -- Updated_at trigger
    CREATE OR REPLACE FUNCTION app_public.set_updated_at()
    RETURNS TRIGGER AS \$\$
    BEGIN
        NEW.updated_at = now();
        RETURN NEW;
    END;
    \$\$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS notes_updated_at ON app_public.notes;
    CREATE TRIGGER notes_updated_at
        BEFORE UPDATE ON app_public.notes
        FOR EACH ROW
        EXECUTE FUNCTION app_public.set_updated_at();

    -- RLS
    ALTER TABLE app_public.notes ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS select_own ON app_public.notes;
    CREATE POLICY select_own ON app_public.notes
        FOR SELECT USING (user_id = current_setting('jwt.claims.user_id', true));

    DROP POLICY IF EXISTS insert_own ON app_public.notes;
    CREATE POLICY insert_own ON app_public.notes
        FOR INSERT WITH CHECK (user_id = current_setting('jwt.claims.user_id', true));

    DROP POLICY IF EXISTS update_own ON app_public.notes;
    CREATE POLICY update_own ON app_public.notes
        FOR UPDATE USING (user_id = current_setting('jwt.claims.user_id', true));

    DROP POLICY IF EXISTS delete_own ON app_public.notes;
    CREATE POLICY delete_own ON app_public.notes
        FOR DELETE USING (user_id = current_setting('jwt.claims.user_id', true));

    -- Explicit grants (in addition to DEFAULT PRIVILEGES)
    GRANT SELECT, INSERT, UPDATE, DELETE ON app_public.notes TO app_authenticated;
    GRANT USAGE, SELECT ON SEQUENCE app_public.notes_id_seq TO app_authenticated;
EOSQL

# Shadow database: grant schema creation to app_postgraphile (needed by graphile-migrate)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "app_shadow" --port "$POSTGRES_PORT" <<-EOSQL
    GRANT ALL ON DATABASE app_shadow TO app_postgraphile;
    GRANT ALL ON SCHEMA public TO app_postgraphile;
EOSQL
