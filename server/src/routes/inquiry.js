import { Router } from 'express';
import pool from '../config/db.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

// POST /api/inquiry — 문의 등록
router.post('/', requireAuth, async (req, res) => {
  try {
    const { category, title, content } = req.body;

    if (!category || !title?.trim() || !content?.trim()) {
      return res.status(400).json({ error: 'category, title, content are required' });
    }

    const result = await pool.query(
      `INSERT INTO inquiries (uid, email, category, title, content)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, category, title, content, status, created_at`,
      [req.uid, req.userEmail || null, category, title.trim(), content.trim()]
    );

    res.json({ success: true, inquiry: result.rows[0] });
  } catch (error) {
    console.error('Create inquiry error:', error);
    res.status(500).json({ error: 'Failed to create inquiry' });
  }
});

// GET /api/inquiry — 내 문의 목록
router.get('/', requireAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, category, title, content, status, reply, replied_at, is_read, created_at
       FROM inquiries
       WHERE uid = $1
       ORDER BY created_at DESC
       LIMIT 50`,
      [req.uid]
    );

    res.json({ inquiries: result.rows });
  } catch (error) {
    console.error('Get inquiries error:', error);
    res.status(500).json({ error: 'Failed to get inquiries' });
  }
});

// GET /api/inquiry/unread-count — 읽지 않은 답변 수
router.get('/unread-count', requireAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT COUNT(*) FROM inquiries
       WHERE uid = $1 AND status = 'replied' AND is_read = FALSE`,
      [req.uid]
    );

    res.json({ count: parseInt(result.rows[0].count) });
  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({ error: 'Failed to get unread count' });
  }
});

// PUT /api/inquiry/:id/read — 읽음 처리
router.put('/:id/read', requireAuth, async (req, res) => {
  try {
    await pool.query(
      `UPDATE inquiries SET is_read = TRUE WHERE id = $1 AND uid = $2`,
      [req.params.id, req.uid]
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Mark read error:', error);
    res.status(500).json({ error: 'Failed to mark as read' });
  }
});

export default router;
