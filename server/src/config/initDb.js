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
    CREATE INDEX IF NOT EXISTS idx_ticket_txn_created_at ON ticket_transactions(created_at);
    CREATE INDEX IF NOT EXISTS idx_ticket_txn_type ON ticket_transactions(type);

    CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

    CREATE TABLE IF NOT EXISTS inquiries (
      id SERIAL PRIMARY KEY,
      uid TEXT NOT NULL,
      email TEXT,
      category TEXT NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      status TEXT DEFAULT 'pending',
      reply TEXT,
      replied_at TIMESTAMPTZ,
      is_read BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMPTZ DEFAULT now()
    );
    CREATE INDEX IF NOT EXISTS idx_inquiries_uid ON inquiries(uid);

    CREATE TABLE IF NOT EXISTS user_results (
      uid        TEXT NOT NULL,
      type       TEXT NOT NULL,
      params     JSONB,
      result     JSONB NOT NULL,
      year       INT,
      date       DATE,
      created_at TIMESTAMPTZ DEFAULT now(),
      updated_at TIMESTAMPTZ DEFAULT now(),
      PRIMARY KEY (uid, type)
    );

    CREATE TABLE IF NOT EXISTS admin_accounts (
      id SERIAL PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );
    INSERT INTO admin_accounts (username, password) VALUES ('jiny', '1204') ON CONFLICT DO NOTHING;

    CREATE TABLE IF NOT EXISTS iap_products (
      id SERIAL PRIMARY KEY,
      product_id TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      ticket_count INT NOT NULL,
      price_krw INT NOT NULL DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      sort_order INT DEFAULT 0,
      created_at TIMESTAMPTZ DEFAULT now(),
      updated_at TIMESTAMPTZ DEFAULT now()
    );
    INSERT INTO iap_products (product_id, name, ticket_count, price_krw, sort_order)
    VALUES
      ('saju_ticket_3', '사주 티켓 3장', 3, 3900, 1),
      ('saju_ticket_10', '사주 티켓 10장', 10, 9900, 2),
      ('saju_ticket_30', '사주 티켓 30장', 30, 24900, 3)
    ON CONFLICT (product_id) DO NOTHING;
  `);

  console.log('DB tables initialized');
}
