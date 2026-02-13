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

# Shadow database: grant schema creation to app_postgraphile (needed by graphile-migrate)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "app_shadow" --port "$POSTGRES_PORT" <<-EOSQL
    GRANT ALL ON DATABASE app_shadow TO app_postgraphile;
    GRANT ALL ON SCHEMA public TO app_postgraphile;
EOSQL
