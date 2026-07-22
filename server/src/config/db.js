import 'dotenv/config';
import pg from 'pg';

const connectionString = process.env.DATABASE_URL?.trim();

if (!connectionString) {
  throw new Error('[DB] DATABASE_URL is not set.');
}

const pool = new pg.Pool({
  connectionString,
});

export default pool;
