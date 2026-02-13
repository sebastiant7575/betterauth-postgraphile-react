#!/bin/bash
set -e

echo "Waiting for PostgreSQL..."
until node -e "
  import('pg').then(({default: pg}) => {
    const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
    pool.query('SELECT 1').then(() => { pool.end(); process.exit(0); }).catch(() => { pool.end(); process.exit(1); });
  });
" 2>/dev/null; do
  sleep 1
done
echo "PostgreSQL is ready."

echo "Running graphile-migrate reset..."
npx graphile-migrate reset --erase 2>&1

echo "Starting server..."
exec npx tsx src/index.ts
