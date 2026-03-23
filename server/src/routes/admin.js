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
    const { status, dateFrom, dateTo } = req.query;
    const conditions = [];
    const params = [];
    let pi = 0;

    if (status && status !== 'all') { pi++; conditions.push(`i.status = $${pi}`); params.push(status); }
    if (dateFrom) { pi++; conditions.push(`i.created_at >= $${pi}`); params.push(dateFrom); }
    if (dateTo) { pi++; conditions.push(`i.created_at < $${pi}::date + 1`); params.push(dateTo); }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const result = await pool.query(
      `SELECT i.*, u.email AS user_email
       FROM inquiries i
       LEFT JOIN users u ON u.uid = i.uid
       ${where}
       ORDER BY i.created_at DESC LIMIT 100`,
      params
    );
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
    const [totalUsers, todayUsers, purchases, todayConsumption, activeUsers, serviceUsage, totalReferrals, todayRev, pendingInq] = await Promise.all([
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
      pool.query(`
        SELECT COUNT(*)::int AS count, COALESCE(SUM(p.price_krw), 0)::bigint AS revenue
        FROM ticket_transactions tt
        LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
        WHERE tt.type = 'purchase' AND tt.created_at >= CURRENT_DATE
      `),
      pool.query("SELECT COUNT(*)::int AS count FROM inquiries WHERE status = 'pending'"),
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
      todayRevenue: parseInt(todayRev.rows[0].revenue),
      todayPurchaseCount: todayRev.rows[0].count,
      pendingInquiries: pendingInq.rows[0].count,
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

    const [userResult, balanceResult, txResult, purchaseResult, resultsCount, compatCount, referralsMade, referredBy, userResults, compatHistory, teamCompatHistory, nameHistory, referredUsers] = await Promise.all([
      pool.query('SELECT * FROM users WHERE uid = $1', [uid]),
      pool.query('SELECT balance FROM tickets WHERE uid = $1', [uid]),
      pool.query('SELECT * FROM ticket_transactions WHERE uid = $1 ORDER BY created_at DESC LIMIT 50', [uid]),
      pool.query(`
        SELECT p.id, p.amount, p.ref_id, p.created_at, p.platform, p.product_id,
               COALESCE(ip.name, COALESCE(p.product_id, p.ref_id)) AS product_name,
               COALESCE(ip.price_krw, 0) AS price_krw,
               r.id AS refund_id, r.created_at AS refunded_at
        FROM ticket_transactions p
        LEFT JOIN ticket_transactions r
          ON r.ref_id = CONCAT('refund:', p.id::text) AND r.type = 'refund'
        LEFT JOIN iap_products ip ON ip.product_id = COALESCE(p.product_id, p.ref_id)
        WHERE p.uid = $1 AND p.type = 'purchase'
        ORDER BY p.created_at DESC
      `, [uid]),
      pool.query('SELECT COUNT(*) AS count FROM user_results WHERE uid = $1', [uid]),
      pool.query('SELECT COUNT(*) AS count FROM compatibility_history WHERE uid = $1', [uid]),
      pool.query('SELECT COUNT(*) AS count FROM referrals WHERE referrer_uid = $1', [uid]),
      pool.query(`SELECT r.referrer_uid, u.email AS referrer_email, r.created_at AS referral_date FROM referrals r LEFT JOIN users u ON u.uid = r.referrer_uid WHERE r.referred_uid = $1`, [uid]),
      pool.query('SELECT type, params, result, year, date, created_at FROM user_results WHERE uid = $1 ORDER BY created_at DESC', [uid]),
      pool.query('SELECT id, my_birth_date, my_birth_time, my_gender, partner_birth_date, partner_birth_time, partner_gender, relationship, result, created_at FROM compatibility_history WHERE uid = $1 ORDER BY created_at DESC LIMIT 20', [uid]),
      pool.query('SELECT id, members, relationship, result, created_at FROM team_compatibility_history WHERE uid = $1 ORDER BY created_at DESC LIMIT 20', [uid]),
      pool.query('SELECT id, mode, name, last_name, birth_date, birth_time, gender, result, created_at FROM name_history WHERE uid = $1 ORDER BY created_at DESC LIMIT 20', [uid]),
      pool.query('SELECT r.referred_uid, u.email, r.created_at FROM referrals r LEFT JOIN users u ON u.uid = r.referred_uid WHERE r.referrer_uid = $1 ORDER BY r.created_at DESC', [uid]),
    ]);

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      user: userResult.rows[0],
      balance: balanceResult.rows[0]?.balance ?? 0,
      transactions: txResult.rows,
      purchases: purchaseResult.rows,
      resultsCount: parseInt(resultsCount.rows[0].count),
      compatibilityCount: parseInt(compatCount.rows[0].count),
      referralsMade: parseInt(referralsMade.rows[0].count),
      referredBy: referredBy.rows[0] || null,
      userResults: userResults.rows,
      compatibilityHistory: compatHistory.rows,
      teamCompatibilityHistory: teamCompatHistory.rows,
      nameHistory: nameHistory.rows,
      referredUsers: referredUsers.rows,
    });
  } catch (error) {
    console.error('Get user detail error:', error);
    res.status(500).json({ error: 'Failed to get user detail' });
  }
});

// PUT /api/admin/users/:uid/referral-code — 추천코드 변경
router.put('/users/:uid/referral-code', adminAuth, async (req, res) => {
  try {
    const { uid } = req.params;
    const { referralCode } = req.body;

    if (!referralCode?.trim()) {
      return res.status(400).json({ error: 'referralCode is required' });
    }

    const code = referralCode.trim().toUpperCase();

    const dup = await pool.query('SELECT uid FROM users WHERE referral_code = $1 AND uid != $2', [code, uid]);
    if (dup.rows.length > 0) {
      return res.status(409).json({ error: '이미 사용 중인 추천 코드입니다.' });
    }

    await pool.query('UPDATE users SET referral_code = $1 WHERE uid = $2', [code, uid]);
    res.json({ success: true, referralCode: code });
  } catch (error) {
    console.error('Update referral code error:', error);
    res.status(500).json({ error: 'Failed to update referral code' });
  }
});

// POST /api/admin/users/:uid/grant-tickets — 티켓 지급
router.post('/users/:uid/grant-tickets', adminAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    const { uid } = req.params;
    const { amount, memo } = req.body;

    if (amount === 0 || amount === undefined || amount === null || !Number.isInteger(amount)) {
      return res.status(400).json({ error: 'amount must be a non-zero integer' });
    }

    await client.query('BEGIN');

    if (amount < 0) {
      const balCheck = await client.query('SELECT balance FROM tickets WHERE uid = $1', [uid]);
      const currentBalance = balCheck.rows[0]?.balance ?? 0;
      if (currentBalance + amount < 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `잔액 부족: 현재 ${currentBalance}장, 회수 요청 ${Math.abs(amount)}장` });
      }
    }

    await client.query(
      `INSERT INTO tickets (uid, balance, updated_at) VALUES ($1, $2, now())
       ON CONFLICT (uid) DO UPDATE SET balance = tickets.balance + $2, updated_at = now()`,
      [uid, amount]
    );

    const balResult = await client.query('SELECT balance FROM tickets WHERE uid = $1', [uid]);
    const balanceAfter = balResult.rows[0].balance;

    const type = amount < 0 ? 'admin_revoke' : 'admin_grant';
    const refId = memo?.trim() ? `admin:${req.admin.username}:${memo.trim()}` : `admin:${req.admin.username}`;

    await client.query(
      `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id, created_at)
       VALUES ($1, $2, $3, $4, $5, now())`,
      [uid, type, amount, balanceAfter, refId]
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

// ── Refund Helper ──

async function processRefund(client, transactionId, uid) {
  // 1. 해당 구매 트랜잭션 조회
  const txResult = await client.query(
    "SELECT * FROM ticket_transactions WHERE id = $1 AND type = 'purchase'",
    [transactionId]
  );
  if (txResult.rows.length === 0) {
    return { error: '해당 구매 건을 찾을 수 없습니다.', status: 404 };
  }
  const purchaseTx = txResult.rows[0];
  const txUid = uid || purchaseTx.uid;

  // 2. 이미 환불됐는지 확인
  const refundCheck = await client.query(
    "SELECT id FROM ticket_transactions WHERE ref_id = $1 AND type = 'refund'",
    [`refund:${transactionId}`]
  );
  if (refundCheck.rows.length > 0) {
    return { error: '이미 환불된 구매 건입니다.', status: 409 };
  }

  // 3. 잔액에서 티켓 차감 (최소 0)
  await client.query(
    'UPDATE tickets SET balance = GREATEST(balance - $1, 0), updated_at = now() WHERE uid = $2',
    [purchaseTx.amount, txUid]
  );
  const balResult = await client.query('SELECT balance FROM tickets WHERE uid = $1', [txUid]);
  const balanceAfter = balResult.rows[0]?.balance ?? 0;

  // 4. 환불 트랜잭션 기록
  await client.query(
    `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id, created_at)
     VALUES ($1, 'refund', $2, $3, $4, now())`,
    [txUid, -purchaseTx.amount, balanceAfter, `refund:${transactionId}`]
  );

  // 5. 추천 회수 판단: 환불 후 남은 유효 구매 건수 확인
  const remainResult = await client.query(
    `SELECT COUNT(*) AS count FROM ticket_transactions p
     WHERE p.uid = $1 AND p.type = 'purchase'
       AND NOT EXISTS (
         SELECT 1 FROM ticket_transactions r
         WHERE r.ref_id = CONCAT('refund:', p.id::text) AND r.type = 'refund'
       )`,
    [txUid]
  );
  const remainingPurchases = parseInt(remainResult.rows[0].count);

  let referralRevoked = false;
  if (remainingPurchases === 0) {
    const refRow = await client.query(
      'SELECT referrer_uid FROM referrals WHERE referred_uid = $1',
      [txUid]
    );
    if (refRow.rows.length > 0) {
      const referrerUid = refRow.rows[0].referrer_uid;
      for (const targetUid of [txUid, referrerUid]) {
        await client.query(
          'UPDATE tickets SET balance = GREATEST(balance - 3, 0), updated_at = now() WHERE uid = $1',
          [targetUid]
        );
        const bRes = await client.query('SELECT balance FROM tickets WHERE uid = $1', [targetUid]);
        const bAfter = bRes.rows[0]?.balance ?? 0;
        await client.query(
          `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id, created_at)
           VALUES ($1, 'refund_referral', -3, $2, $3, now())`,
          [targetUid, bAfter, `refund_referral:${txUid}`]
        );
      }
      await client.query('DELETE FROM referrals WHERE referred_uid = $1', [txUid]);
      referralRevoked = true;
    }
  }

  return { success: true, balance: balanceAfter, referralRevoked, uid: txUid };
}

// POST /api/admin/users/:uid/refund — 구매 환불
router.post('/users/:uid/refund', adminAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    const { uid } = req.params;
    const { transactionId } = req.body;

    if (!transactionId) {
      return res.status(400).json({ error: 'transactionId is required' });
    }

    await client.query('BEGIN');
    const result = await processRefund(client, transactionId, uid);
    if (result.error) {
      await client.query('ROLLBACK');
      return res.status(result.status).json({ error: result.error });
    }
    await client.query('COMMIT');

    res.json({ success: true, balance: result.balance, referralRevoked: result.referralRevoked });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Refund error:', error);
    res.status(500).json({ error: 'Failed to process refund' });
  } finally {
    client.release();
  }
});

// ── Purchase Management ──

// GET /api/admin/purchases — 전체 구매 목록 (필터, 페이지네이션)
router.get('/purchases', adminAuth, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
    const offset = (page - 1) * limit;
    const { dateFrom, dateTo, productId, refundStatus, email, environment } = req.query;

    const conditions = ["tt.type = 'purchase'"];
    const params = [];
    let pi = 0;

    if (dateFrom) { pi++; conditions.push(`tt.created_at >= $${pi}`); params.push(dateFrom); }
    if (dateTo) { pi++; conditions.push(`tt.created_at < $${pi}::date + 1`); params.push(dateTo); }
    if (productId) { pi++; conditions.push(`COALESCE(tt.product_id, tt.ref_id) = $${pi}`); params.push(productId); }
    if (email) { pi++; conditions.push(`u.email ILIKE $${pi}`); params.push(`%${email}%`); }
    if (environment) { pi++; conditions.push(`COALESCE(tt.environment, 'Production') = $${pi}`); params.push(environment); }

    if (refundStatus === 'refunded') {
      conditions.push(`EXISTS (SELECT 1 FROM ticket_transactions r WHERE r.ref_id = CONCAT('refund:', tt.id::text) AND r.type = 'refund')`);
    } else if (refundStatus === 'normal') {
      conditions.push(`NOT EXISTS (SELECT 1 FROM ticket_transactions r WHERE r.ref_id = CONCAT('refund:', tt.id::text) AND r.type = 'refund')`);
    }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countQuery = `
      SELECT COUNT(*) AS count
      FROM ticket_transactions tt
      LEFT JOIN users u ON u.uid = tt.uid
      ${where}
    `;
    const dataQuery = `
      SELECT tt.id, tt.uid, tt.amount, tt.balance_after, tt.ref_id, tt.created_at,
             tt.platform, tt.product_id, COALESCE(tt.environment, 'Production') AS environment,
             u.email,
             COALESCE(p.name, COALESCE(tt.product_id, tt.ref_id)) AS product_name,
             COALESCE(p.price_krw, 0) AS price_krw,
             CASE WHEN r.id IS NOT NULL THEN true ELSE false END AS is_refunded,
             r.created_at AS refunded_at
      FROM ticket_transactions tt
      LEFT JOIN users u ON u.uid = tt.uid
      LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
      LEFT JOIN ticket_transactions r ON r.ref_id = CONCAT('refund:', tt.id::text) AND r.type = 'refund'
      ${where}
      ORDER BY tt.created_at DESC
      LIMIT $${pi + 1} OFFSET $${pi + 2}
    `;

    const [countResult, dataResult] = await Promise.all([
      pool.query(countQuery, params),
      pool.query(dataQuery, [...params, limit, offset]),
    ]);

    const total = parseInt(countResult.rows[0].count);

    res.json({
      purchases: dataResult.rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('Get purchases error:', error);
    res.status(500).json({ error: 'Failed to get purchases' });
  }
});

// GET /api/admin/purchases/summary — 구매 요약 통계
router.get('/purchases/summary', adminAuth, async (req, res) => {
  try {
    const { environment } = req.query;
    const envCond = environment ? `AND COALESCE(tt.environment, 'Production') = '${environment.replace(/'/g, '')}'` : '';

    const [todayRev, totalRev, totalRefund, platformRev] = await Promise.all([
      pool.query(`
        SELECT COUNT(*)::int AS count, COALESCE(SUM(p.price_krw), 0)::bigint AS revenue
        FROM ticket_transactions tt
        LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
        WHERE tt.type = 'purchase' AND tt.created_at >= CURRENT_DATE ${envCond}
      `),
      pool.query(`
        SELECT COUNT(*)::int AS count, COALESCE(SUM(p.price_krw), 0)::bigint AS revenue
        FROM ticket_transactions tt
        LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
        WHERE tt.type = 'purchase' ${envCond}
      `),
      pool.query(`
        SELECT COUNT(*)::int AS count, COALESCE(SUM(ABS(tt.amount)), 0)::int AS tickets
        FROM ticket_transactions tt
        WHERE tt.type = 'refund'
      `),
      pool.query(`
        SELECT COALESCE(tt.platform, 'unknown') AS platform,
               COUNT(*)::int AS count,
               COALESCE(SUM(p.price_krw), 0)::bigint AS revenue
        FROM ticket_transactions tt
        LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
        WHERE tt.type = 'purchase' ${envCond}
        GROUP BY COALESCE(tt.platform, 'unknown')
      `),
    ]);

    const platformMap = {};
    platformRev.rows.forEach(r => { platformMap[r.platform] = { count: r.count, revenue: parseInt(r.revenue) }; });

    res.json({
      todayRevenue: parseInt(todayRev.rows[0].revenue),
      todayPurchaseCount: todayRev.rows[0].count,
      totalRevenue: parseInt(totalRev.rows[0].revenue),
      totalPurchaseCount: totalRev.rows[0].count,
      totalRefundCount: totalRefund.rows[0].count,
      totalRefundTickets: totalRefund.rows[0].tickets,
      platformRevenue: platformMap,
    });
  } catch (error) {
    console.error('Get purchase summary error:', error);
    res.status(500).json({ error: 'Failed to get purchase summary' });
  }
});

// POST /api/admin/purchases/:id/refund — 구매건 직접 환불
router.post('/purchases/:id/refund', adminAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    const transactionId = req.params.id;

    await client.query('BEGIN');
    const result = await processRefund(client, transactionId);
    if (result.error) {
      await client.query('ROLLBACK');
      return res.status(result.status).json({ error: result.error });
    }
    await client.query('COMMIT');

    res.json({ success: true, balance: result.balance, referralRevoked: result.referralRevoked });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Purchase refund error:', error);
    res.status(500).json({ error: 'Failed to process refund' });
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

// ── Detailed Stats Endpoints ──

function getPeriodFilter(period) {
  switch (period) {
    case '30d': return "NOW() - INTERVAL '30 days'";
    case '90d': return "NOW() - INTERVAL '90 days'";
    case 'all': return null;
    default: return "NOW() - INTERVAL '7 days'";
  }
}

// GET /api/admin/stats/users — 유저 성장 분석
router.get('/stats/users', adminAuth, async (req, res) => {
  try {
    const since = getPeriodFilter(req.query.period);
    const w = since ? `WHERE created_at >= ${since}` : '';

    const [daily, total, periodQ, gender, decade, activated] = await Promise.all([
      pool.query(`SELECT DATE(created_at) AS date, COUNT(*)::int AS count FROM users ${w} GROUP BY DATE(created_at) ORDER BY date`),
      pool.query('SELECT COUNT(*)::int AS count FROM users'),
      pool.query(`SELECT COUNT(*)::int AS count FROM users ${w}`),
      pool.query(`SELECT COALESCE(gender, 'unknown') AS label, COUNT(*)::int AS count FROM users ${w} GROUP BY label ORDER BY count DESC`),
      pool.query(`
        SELECT CASE WHEN birth_date IS NULL OR birth_date = '' THEN '미입력'
          ELSE CONCAT(SUBSTRING(birth_date FROM 1 FOR 3), '0년대') END AS label,
          COUNT(*)::int AS count
        FROM users ${w} GROUP BY label ORDER BY label
      `),
      since
        ? pool.query(`SELECT COUNT(DISTINCT u.uid)::int AS count FROM users u JOIN ticket_transactions tt ON tt.uid = u.uid AND tt.amount < 0 WHERE u.created_at >= ${since}`)
        : pool.query('SELECT COUNT(DISTINCT u.uid)::int AS count FROM users u JOIN ticket_transactions tt ON tt.uid = u.uid AND tt.amount < 0'),
    ]);

    const totalCount = total.rows[0].count;
    const periodCount = periodQ.rows[0].count;
    const activatedCount = activated.rows[0].count;

    res.json({
      dailySignups: daily.rows,
      totalUsers: totalCount,
      periodUsers: periodCount,
      genderDistribution: gender.rows,
      decadeDistribution: decade.rows,
      activationRate: totalCount > 0 ? +(activatedCount / totalCount * 100).toFixed(1) : 0,
      activatedUsers: activatedCount,
    });
  } catch (error) {
    console.error('Stats users error:', error);
    res.status(500).json({ error: 'Failed to get user stats' });
  }
});

// GET /api/admin/stats/revenue — 매출 분석
router.get('/stats/revenue', adminAuth, async (req, res) => {
  try {
    const since = getPeriodFilter(req.query.period);
    const a = since ? `AND tt.created_at >= ${since}` : '';

    const [dailyRev, totalRev, periodRev, ranking, paying, totalUsers] = await Promise.all([
      pool.query(`
        SELECT DATE(tt.created_at) AS date, COUNT(*)::int AS count, COALESCE(SUM(p.price_krw), 0)::int AS revenue
        FROM ticket_transactions tt LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
        WHERE tt.type = 'purchase' ${a}
        GROUP BY DATE(tt.created_at) ORDER BY date
      `),
      pool.query(`
        SELECT COUNT(*)::int AS count, COALESCE(SUM(p.price_krw), 0)::bigint AS revenue
        FROM ticket_transactions tt LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
        WHERE tt.type = 'purchase'
      `),
      since ? pool.query(`
        SELECT COUNT(*)::int AS count, COALESCE(SUM(p.price_krw), 0)::bigint AS revenue
        FROM ticket_transactions tt LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
        WHERE tt.type = 'purchase' AND tt.created_at >= ${since}
      `) : null,
      pool.query(`
        SELECT tt.ref_id AS product_id, COALESCE(p.name, tt.ref_id) AS name,
               COUNT(*)::int AS sales, COALESCE(SUM(p.price_krw), 0)::bigint AS revenue, SUM(tt.amount)::int AS tickets
        FROM ticket_transactions tt LEFT JOIN iap_products p ON p.product_id = COALESCE(tt.product_id, tt.ref_id)
        WHERE tt.type = 'purchase' ${a}
        GROUP BY tt.ref_id, p.name ORDER BY sales DESC
      `),
      pool.query(`SELECT COUNT(DISTINCT uid)::int AS count FROM ticket_transactions WHERE type = 'purchase' ${since ? `AND created_at >= ${since}` : ''}`),
      pool.query('SELECT COUNT(*)::int AS count FROM users'),
    ]);

    const tRev = totalRev.rows[0];
    const pRev = periodRev ? periodRev.rows[0] : tRev;
    const payCount = paying.rows[0].count;
    const userCount = totalUsers.rows[0].count;

    res.json({
      dailyRevenue: dailyRev.rows,
      totalRevenue: parseInt(tRev.revenue),
      totalPurchases: tRev.count,
      periodRevenue: parseInt(pRev.revenue),
      periodPurchases: pRev.count,
      productRanking: ranking.rows,
      payingUsers: payCount,
      conversionRate: userCount > 0 ? +(payCount / userCount * 100).toFixed(1) : 0,
      arpu: payCount > 0 ? Math.round(parseInt(pRev.revenue) / payCount) : 0,
    });
  } catch (error) {
    console.error('Stats revenue error:', error);
    res.status(500).json({ error: 'Failed to get revenue stats' });
  }
});

// GET /api/admin/stats/services — 서비스 이용 분석
router.get('/stats/services', adminAuth, async (req, res) => {
  try {
    const since = getPeriodFilter(req.query.period);
    const a = since ? `AND created_at >= ${since}` : '';

    const [ranking, dailyTrend, hourly, weekday] = await Promise.all([
      pool.query(`SELECT ref_id, COUNT(*)::int AS count, COALESCE(SUM(ABS(amount)), 0)::int AS tickets FROM ticket_transactions WHERE amount < 0 ${a} GROUP BY ref_id ORDER BY count DESC`),
      pool.query(`SELECT DATE(created_at) AS date, ref_id, COUNT(*)::int AS count FROM ticket_transactions WHERE amount < 0 ${a} GROUP BY DATE(created_at), ref_id ORDER BY date`),
      pool.query(`SELECT EXTRACT(HOUR FROM created_at)::int AS hour, COUNT(*)::int AS count FROM ticket_transactions WHERE amount < 0 ${a} GROUP BY hour ORDER BY hour`),
      pool.query(`SELECT EXTRACT(DOW FROM created_at)::int AS dow, COUNT(*)::int AS count FROM ticket_transactions WHERE amount < 0 ${a} GROUP BY dow ORDER BY dow`),
    ]);

    res.json({
      ranking: ranking.rows,
      dailyTrend: dailyTrend.rows,
      hourlyDistribution: hourly.rows,
      weekdayDistribution: weekday.rows,
    });
  } catch (error) {
    console.error('Stats services error:', error);
    res.status(500).json({ error: 'Failed to get service stats' });
  }
});

// GET /api/admin/stats/tickets — 티켓 경제 분석
router.get('/stats/tickets', adminAuth, async (req, res) => {
  try {
    const since = getPeriodFilter(req.query.period);
    const a = since ? `AND created_at >= ${since}` : '';

    const [dailyFlow, inflowByType, avgBal, zeroBal, dist] = await Promise.all([
      pool.query(`
        SELECT DATE(created_at) AS date,
               COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0)::int AS inflow,
               COALESCE(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END), 0)::int AS outflow
        FROM ticket_transactions WHERE 1=1 ${a}
        GROUP BY DATE(created_at) ORDER BY date
      `),
      pool.query(`SELECT type, COALESCE(SUM(amount), 0)::int AS total, COUNT(*)::int AS count FROM ticket_transactions WHERE amount > 0 ${a} GROUP BY type ORDER BY total DESC`),
      pool.query('SELECT COALESCE(AVG(balance), 0)::numeric(10,1) AS avg FROM tickets'),
      pool.query('SELECT COUNT(*)::int AS count FROM tickets WHERE balance = 0'),
      pool.query(`
        SELECT CASE WHEN balance = 0 THEN '0' WHEN balance BETWEEN 1 AND 5 THEN '1-5'
          WHEN balance BETWEEN 6 AND 10 THEN '6-10' WHEN balance BETWEEN 11 AND 20 THEN '11-20'
          ELSE '21+' END AS range,
          COUNT(*)::int AS count
        FROM tickets GROUP BY range ORDER BY MIN(balance)
      `),
    ]);

    res.json({
      dailyFlow: dailyFlow.rows,
      inflowByType: inflowByType.rows,
      avgBalance: parseFloat(avgBal.rows[0].avg),
      zeroBalanceUsers: zeroBal.rows[0].count,
      balanceDistribution: dist.rows,
    });
  } catch (error) {
    console.error('Stats tickets error:', error);
    res.status(500).json({ error: 'Failed to get ticket stats' });
  }
});

// GET /api/admin/stats/engagement — 인게이지먼트 분석
router.get('/stats/engagement', adminAuth, async (req, res) => {
  try {
    const since = getPeriodFilter(req.query.period);
    const w = since ? `WHERE created_at >= ${since}` : '';

    const [dau, wau, mau, shares, topRef, compatTypes, nameRatio, cacheStats] = await Promise.all([
      pool.query(`SELECT DATE(created_at) AS date, COUNT(DISTINCT uid)::int AS count FROM ticket_transactions ${w} GROUP BY DATE(created_at) ORDER BY date`),
      pool.query("SELECT COUNT(DISTINCT uid)::int AS count FROM ticket_transactions WHERE created_at >= NOW() - INTERVAL '7 days'"),
      pool.query("SELECT COUNT(DISTINCT uid)::int AS count FROM ticket_transactions WHERE created_at >= NOW() - INTERVAL '30 days'"),
      pool.query(`SELECT DATE(created_at) AS date, COUNT(*)::int AS count FROM shared_results ${w} GROUP BY DATE(created_at) ORDER BY date`),
      pool.query(`SELECT r.referrer_uid, COUNT(*)::int AS count, u.email FROM referrals r LEFT JOIN users u ON u.uid = r.referrer_uid GROUP BY r.referrer_uid, u.email ORDER BY count DESC LIMIT 10`),
      pool.query(`SELECT relationship, COUNT(*)::int AS count FROM compatibility_history ${w} GROUP BY relationship ORDER BY count DESC`),
      pool.query(`SELECT mode, COUNT(*)::int AS count FROM name_history ${w} GROUP BY mode ORDER BY count DESC`),
      Promise.all([
        pool.query('SELECT COUNT(*)::int AS count FROM fortune_cache'),
        pool.query('SELECT COUNT(*)::int AS count FROM daily_cache'),
        pool.query('SELECT COUNT(*)::int AS count FROM compatibility_cache'),
        pool.query('SELECT COUNT(*)::int AS count FROM name_analysis_cache'),
      ]),
    ]);

    const dauValues = dau.rows.map(r => r.count);
    const avgDau = dauValues.length > 0 ? +(dauValues.reduce((s, v) => s + v, 0) / dauValues.length).toFixed(1) : 0;
    const mauCount = mau.rows[0].count;

    res.json({
      dauTrend: dau.rows,
      avgDau,
      wau: wau.rows[0].count,
      mau: mauCount,
      stickiness: mauCount > 0 ? +(avgDau / mauCount * 100).toFixed(1) : 0,
      shareTrend: shares.rows,
      topReferrers: topRef.rows,
      compatibilityTypes: compatTypes.rows,
      nameAnalysisRatio: nameRatio.rows,
      cacheStats: {
        fortune: cacheStats[0].rows[0].count,
        daily: cacheStats[1].rows[0].count,
        compatibility: cacheStats[2].rows[0].count,
        nameAnalysis: cacheStats[3].rows[0].count,
      },
    });
  } catch (error) {
    console.error('Stats engagement error:', error);
    res.status(500).json({ error: 'Failed to get engagement stats' });
  }
});

export default router;
