import pool from './db.js';

export async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS fortune_cache (
      cache_key  TEXT PRIMARY KEY,
      result     JSONB NOT NULL,
      year       INT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS daily_cache (
      cache_key  TEXT PRIMARY KEY,
      result     JSONB NOT NULL,
      date       DATE NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS compatibility_cache (
      cache_key  TEXT PRIMARY KEY,
      result     JSONB NOT NULL,
      year       INT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS name_analysis_cache (
      cache_key  TEXT PRIMARY KEY,
      result     JSONB NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS users (
      uid         TEXT PRIMARY KEY,
      email       TEXT,
      birth_date  TEXT,
      birth_time  TEXT,
      gender      TEXT,
      created_at  TIMESTAMPTZ DEFAULT now(),
      updated_at  TIMESTAMPTZ DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS compatibility_history (
      id                 SERIAL PRIMARY KEY,
      uid                TEXT NOT NULL,
      cache_key          TEXT NOT NULL,
      my_birth_date      TEXT NOT NULL,
      my_birth_time      TEXT,
      my_gender          TEXT NOT NULL,
      partner_birth_date TEXT NOT NULL,
      partner_birth_time TEXT,
      partner_gender     TEXT NOT NULL,
      relationship       TEXT NOT NULL,
      result             JSONB NOT NULL,
      created_at         TIMESTAMPTZ DEFAULT now()
    );

    CREATE INDEX IF NOT EXISTS idx_compat_history_uid ON compatibility_history(uid);

    CREATE TABLE IF NOT EXISTS tickets (
      uid TEXT PRIMARY KEY,
      balance INT NOT NULL DEFAULT 0,
      updated_at TIMESTAMPTZ DEFAULT now()
    );

    CREATE TABLE IF NOT EXISTS ticket_transactions (
      id SERIAL PRIMARY KEY,
      uid TEXT NOT NULL,
      type TEXT NOT NULL,
      amount INT NOT NULL,
      balance_after INT NOT NULL,
      ref_id TEXT,
      created_at TIMESTAMPTZ DEFAULT now()
    );

    CREATE INDEX IF NOT EXISTS idx_ticket_txn_uid ON ticket_transactions(uid);
  `);

  console.log('DB tables initialized');
}
