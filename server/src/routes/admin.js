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
