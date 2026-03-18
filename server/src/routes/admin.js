import { Router } from 'express';
import jwt from 'jsonwebtoken';
import pool from '../config/db.js';

const router = Router();
const ADMIN_JWT_SECRET = process.env.JWT_SECRET || 'admin-secret-key';

// 관리자 토큰 검증 미들웨어
function adminAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const token = authHeader.split(' ')[1];
    const payload = jwt.verify(token, ADMIN_JWT_SECRET);
    req.admin = payload;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// POST /api/admin/login — 관리자 로그인
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const result = await pool.query(
      'SELECT id, username FROM admin_accounts WHERE username = $1 AND password = $2',
      [username, password]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const admin = result.rows[0];
    const token = jwt.sign(
      { adminId: admin.id, username: admin.username },
      ADMIN_JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({ success: true, token, username: admin.username });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// GET /api/admin/inquiries — 전체 문의 목록
router.get('/inquiries', adminAuth, async (req, res) => {
  try {
    const status = req.query.status;
    let query = `SELECT * FROM inquiries`;
    const params = [];

    if (status && status !== 'all') {
      query += ' WHERE status = $1';
      params.push(status);
    }

    query += ' ORDER BY created_at DESC LIMIT 100';

    const result = await pool.query(query, params);
    res.json({ inquiries: result.rows });
  } catch (error) {
    console.error('Get inquiries error:', error);
    res.status(500).json({ error: 'Failed to get inquiries' });
  }
});

// GET /api/admin/inquiries/:id — 문의 상세
router.get('/inquiries/:id', adminAuth, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM inquiries WHERE id = $1',
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Inquiry not found' });
    }

    res.json({ inquiry: result.rows[0] });
  } catch (error) {
    console.error('Get inquiry detail error:', error);
    res.status(500).json({ error: 'Failed to get inquiry detail' });
  }
});

// PUT /api/admin/inquiries/:id — 답변
router.put('/inquiries/:id', adminAuth, async (req, res) => {
  try {
    const { reply } = req.body;

    if (!reply?.trim()) {
      return res.status(400).json({ error: 'Reply is required' });
    }

    const result = await pool.query(
      `UPDATE inquiries
       SET reply = $1, status = 'replied', replied_at = CURRENT_TIMESTAMP, is_read = FALSE
       WHERE id = $2
       RETURNING *`,
      [reply.trim(), req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Inquiry not found' });
    }

    res.json({ success: true, inquiry: result.rows[0] });
  } catch (error) {
    console.error('Reply inquiry error:', error);
    res.status(500).json({ error: 'Failed to reply' });
  }
});

// ── Dashboard Stats ──

// GET /api/admin/stats — 대시보드 통계
router.get('/stats', adminAuth, async (req, res) => {
  try {
    const [totalUsers, todayUsers, purchases, todayConsumption, activeUsers, serviceUsage, totalReferrals] = await Promise.all([
      pool.query('SELECT COUNT(*) AS count FROM users'),
      pool.query("SELECT COUNT(*) AS count FROM users WHERE created_at >= CURRENT_DATE"),
      pool.query("SELECT COUNT(*) AS count, COALESCE(SUM(amount), 0) AS total_tickets FROM ticket_transactions WHERE type = 'purchase'"),
      pool.query("SELECT COUNT(*) AS count FROM ticket_transactions WHERE amount < 0 AND created_at >= CURRENT_DATE"),
      pool.query(`
        SELECT COUNT(DISTINCT uid) AS count FROM (
          SELECT uid FROM ticket_transactions WHERE created_at >= NOW() - INTERVAL '7 days'
          UNION
          SELECT uid FROM user_results WHERE created_at >= NOW() - INTERVAL '7 days'
        ) AS active
      `),
      pool.query(`
        SELECT ref_id, COUNT(*) AS count, COALESCE(SUM(ABS(amount)), 0) AS total_tickets
        FROM ticket_transactions
        WHERE amount < 0
        GROUP BY ref_id
        ORDER BY count DESC
      `),
      pool.query('SELECT COUNT(*) AS count FROM referrals'),
    ]);

    res.json({
      totalUsers: parseInt(totalUsers.rows[0].count),
      todayUsers: parseInt(todayUsers.rows[0].count),
      purchaseCount: parseInt(purchases.rows[0].count),
      purchaseTickets: parseInt(purchases.rows[0].total_tickets),
      todayConsumption: parseInt(todayConsumption.rows[0].count),
      activeUsers7d: parseInt(activeUsers.rows[0].count),
      serviceUsage: serviceUsage.rows,
      totalReferrals: parseInt(totalReferrals.rows[0].count),
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: 'Failed to get stats' });
  }
});

// ── User Management ──

// GET /api/admin/users — 유저 목록
router.get('/users', adminAuth, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
    const offset = (page - 1) * limit;
    const search = req.query.search?.trim();

    let whereClause = '';
    const params = [];

    if (search) {
      whereClause = 'WHERE u.email ILIKE $1 OR u.uid ILIKE $1';
      params.push(`%${search}%`);
    }

    const countQuery = `SELECT COUNT(*) AS count FROM users u ${whereClause}`;
    const dataQuery = `
      SELECT u.uid, u.email, u.birth_date, u.gender, u.created_at,
             COALESCE(t.balance, 0) AS balance
      FROM users u
      LEFT JOIN tickets t ON t.uid = u.uid
      ${whereClause}
      ORDER BY u.created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const [countResult, dataResult] = await Promise.all([
      pool.query(countQuery, params),
      pool.query(dataQuery, [...params, limit, offset]),
    ]);

    const total = parseInt(countResult.rows[0].count);

    res.json({
      users: dataResult.rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Failed to get users' });
  }
});

// GET /api/admin/users/:uid — 유저 상세
router.get('/users/:uid', adminAuth, async (req, res) => {
  try {
    const { uid } = req.params;

    const [userResult, balanceResult, txResult, resultsCount, compatCount, referralsMade, referredBy] = await Promise.all([
      pool.query('SELECT * FROM users WHERE uid = $1', [uid]),
      pool.query('SELECT balance FROM tickets WHERE uid = $1', [uid]),
      pool.query('SELECT * FROM ticket_transactions WHERE uid = $1 ORDER BY created_at DESC LIMIT 50', [uid]),
      pool.query('SELECT COUNT(*) AS count FROM user_results WHERE uid = $1', [uid]),
      pool.query('SELECT COUNT(*) AS count FROM compatibility_history WHERE uid = $1', [uid]),
      pool.query('SELECT COUNT(*) AS count FROM referrals WHERE referrer_uid = $1', [uid]),
      pool.query(`SELECT r.referrer_uid, u.email AS referrer_email FROM referrals r LEFT JOIN users u ON u.uid = r.referrer_uid WHERE r.referred_uid = $1`, [uid]),
    ]);

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      user: userResult.rows[0],
      balance: balanceResult.rows[0]?.balance ?? 0,
      transactions: txResult.rows,
      resultsCount: parseInt(resultsCount.rows[0].count),
      compatibilityCount: parseInt(compatCount.rows[0].count),
      referralsMade: parseInt(referralsMade.rows[0].count),
      referredBy: referredBy.rows[0] || null,
    });
  } catch (error) {
    console.error('Get user detail error:', error);
    res.status(500).json({ error: 'Failed to get user detail' });
  }
});

// POST /api/admin/users/:uid/grant-tickets — 티켓 지급
router.post('/users/:uid/grant-tickets', adminAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    const { uid } = req.params;
    const { amount } = req.body;

    if (!amount || !Number.isInteger(amount) || amount <= 0) {
      return res.status(400).json({ error: 'amount must be a positive integer' });
    }

    await client.query('BEGIN');

    await client.query(
      `INSERT INTO tickets (uid, balance, updated_at) VALUES ($1, $2, now())
       ON CONFLICT (uid) DO UPDATE SET balance = tickets.balance + $2, updated_at = now()`,
      [uid, amount]
    );

    const balResult = await client.query('SELECT balance FROM tickets WHERE uid = $1', [uid]);
    const balanceAfter = balResult.rows[0].balance;

    await client.query(
      `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id, created_at)
       VALUES ($1, 'admin_grant', $2, $3, $4, now())`,
      [uid, amount, balanceAfter, `admin:${req.admin.username}`]
    );

    await client.query('COMMIT');

    res.json({ success: true, balance: balanceAfter });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Grant tickets error:', error);
    res.status(500).json({ error: 'Failed to grant tickets' });
  } finally {
    client.release();
  }
});

// ── IAP Products CRUD ──

// GET /api/admin/products — 전체 상품 목록
router.get('/products', adminAuth, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM iap_products ORDER BY sort_order ASC, id ASC'
    );
    res.json({ products: result.rows });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({ error: 'Failed to get products' });
  }
});

// POST /api/admin/products — 상품 추가
router.post('/products', adminAuth, async (req, res) => {
  try {
    const { product_id, name, ticket_count, price_krw, is_active, sort_order } = req.body;

    if (!product_id || !name || !ticket_count) {
      return res.status(400).json({ error: 'product_id, name, ticket_count are required' });
    }

    const result = await pool.query(
      `INSERT INTO iap_products (product_id, name, ticket_count, price_krw, is_active, sort_order)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [product_id, name, ticket_count, price_krw ?? 0, is_active ?? true, sort_order ?? 0]
    );

    res.json({ product: result.rows[0] });
  } catch (error) {
    console.error('Create product error:', error);
    if (error.code === '23505') {
      return res.status(409).json({ error: '이미 존재하는 product_id입니다.' });
    }
    res.status(500).json({ error: 'Failed to create product' });
  }
});

// PUT /api/admin/products/:id — 상품 수정
router.put('/products/:id', adminAuth, async (req, res) => {
  try {
    const { name, ticket_count, price_krw, is_active, sort_order } = req.body;

    const result = await pool.query(
      `UPDATE iap_products
       SET name = COALESCE($1, name),
           ticket_count = COALESCE($2, ticket_count),
           price_krw = COALESCE($3, price_krw),
           is_active = COALESCE($4, is_active),
           sort_order = COALESCE($5, sort_order),
           updated_at = now()
       WHERE id = $6
       RETURNING *`,
      [name, ticket_count, price_krw, is_active, sort_order, req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ product: result.rows[0] });
  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({ error: 'Failed to update product' });
  }
});

// DELETE /api/admin/products/:id — 상품 삭제
router.delete('/products/:id', adminAuth, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM iap_products WHERE id = $1 RETURNING *',
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({ error: 'Failed to delete product' });
  }
});

export default router;
