import crypto from 'crypto';
import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import pool from '../config/db.js';
import { getUserResults } from '../services/fortune.js';

const router = Router();

function generateReferralCode() {
  return crypto.randomBytes(4).toString('hex').toUpperCase(); // 8자리
}

/**
 * POST /api/user/saju — 사주 저장/업데이트
 */
router.post('/saju', requireAuth, async (req, res) => {
  try {
    console.log(`[user/saju] POST uid=${req.uid} email=${req.userEmail} body=${JSON.stringify(req.body)}`);
    const { birthDate, birthTime, gender, referralCode } = req.body ?? {};

    if (!birthDate || !gender) {
      console.log('[user/saju] Missing required fields');
      return res.status(400).json({ error: 'birthDate, gender는 필수입니다.' });
    }

    const result = await pool.query(
      `INSERT INTO users (uid, email, birth_date, birth_time, gender, updated_at)
       VALUES ($1, $2, $3, $4, $5, now())
       ON CONFLICT (uid) DO UPDATE
       SET email = $2, birth_date = $3, birth_time = $4, gender = $5, updated_at = now()`,
      [req.uid, req.userEmail, birthDate, birthTime ?? 'unknown', gender],
    );
    console.log(`[user/saju] DB result: rowCount=${result.rowCount}`);

    // 신규 유저에게 무료 티켓 3장 지급
    const ticketResult = await pool.query(
      `INSERT INTO tickets (uid, balance) VALUES ($1, 3) ON CONFLICT DO NOTHING RETURNING balance`,
      [req.uid],
    );

    // 신규 지급된 경우 거래 내역 기록
    if (ticketResult.rowCount > 0) {
      await pool.query(
        `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
         VALUES ($1, 'signup_bonus', 3, 3, 'signup')`,
        [req.uid],
      );

      // 신규 유저에게 referral_code 생성
      let code = generateReferralCode();
      for (let i = 0; i < 5; i++) {
        try {
          await pool.query(
            'UPDATE users SET referral_code = $1 WHERE uid = $2 AND referral_code IS NULL',
            [code, req.uid],
          );
          break;
        } catch {
          code = generateReferralCode();
        }
      }

      // 추천인 코드 처리
      if (referralCode && typeof referralCode === 'string' && referralCode.trim()) {
        try {
          const referrerResult = await pool.query(
            'SELECT uid FROM users WHERE referral_code = $1',
            [referralCode.trim().toUpperCase()],
          );

          if (referrerResult.rows.length > 0) {
            const referrerUid = referrerResult.rows[0].uid;

            // 자기 추천 방지
            if (referrerUid !== req.uid) {
              const client = await pool.connect();
              try {
                await client.query('BEGIN');

                // referrals에 기록 (UNIQUE 제약으로 중복 방지)
                await client.query(
                  'INSERT INTO referrals (referrer_uid, referred_uid) VALUES ($1, $2)',
                  [referrerUid, req.uid],
                );

                // 추천인 티켓 +3
                await client.query(
                  `INSERT INTO tickets (uid, balance, updated_at) VALUES ($1, 3, now())
                   ON CONFLICT (uid) DO UPDATE SET balance = tickets.balance + 3, updated_at = now()`,
                  [referrerUid],
                );
                const referrerBal = await client.query('SELECT balance FROM tickets WHERE uid = $1', [referrerUid]);
                await client.query(
                  `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
                   VALUES ($1, 'referral_bonus', 3, $2, $3)`,
                  [referrerUid, referrerBal.rows[0].balance, `referral:${req.uid}`],
                );

                // 입력자 티켓 +3
                await client.query(
                  `UPDATE tickets SET balance = balance + 3, updated_at = now() WHERE uid = $1`,
                  [req.uid],
                );
                const myBal = await client.query('SELECT balance FROM tickets WHERE uid = $1', [req.uid]);
                await client.query(
                  `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
                   VALUES ($1, 'referral_bonus', 3, $2, $3)`,
                  [req.uid, myBal.rows[0].balance, `referral:${referrerUid}`],
                );

                await client.query('COMMIT');
                console.log(`[user/saju] Referral bonus applied: referrer=${referrerUid}, referred=${req.uid}`);
              } catch (refErr) {
                await client.query('ROLLBACK');
                // 중복 추천 등은 조용히 무시
                console.log(`[user/saju] Referral skipped: ${refErr.message}`);
              } finally {
                client.release();
              }
            }
          }
        } catch (refErr) {
          console.log(`[user/saju] Referral code lookup failed: ${refErr.message}`);
        }
      }
    }

    res.json({ ok: true });
  } catch (err) {
    console.error('[user/saju] Save saju error:', err);
    res.status(500).json({ error: '사주 저장 중 오류가 발생했습니다.' });
  }
});

/**
 * POST /api/user/apply-referral — 추천인 코드 적용 (로그인 시)
 */
router.post('/apply-referral', requireAuth, async (req, res) => {
  try {
    const { referralCode } = req.body ?? {};
    if (!referralCode || typeof referralCode !== 'string' || !referralCode.trim()) {
      return res.json({ applied: false, message: '추천 코드가 비어있습니다.' });
    }

    // 이미 추천을 받은 유저인지 확인
    const { rows: existingRefs } = await pool.query(
      'SELECT id FROM referrals WHERE referred_uid = $1',
      [req.uid],
    );
    if (existingRefs.length > 0) {
      return res.json({ applied: false, message: '이미 추천 코드를 사용하셨습니다.' });
    }

    // 추천인 코드 조회
    const { rows: referrerRows } = await pool.query(
      'SELECT uid FROM users WHERE referral_code = $1',
      [referralCode.trim().toUpperCase()],
    );
    if (referrerRows.length === 0) {
      return res.json({ applied: false, message: '유효하지 않은 추천 코드입니다.' });
    }

    const referrerUid = referrerRows[0].uid;

    // 자기 추천 방지
    if (referrerUid === req.uid) {
      return res.json({ applied: false, message: '자신의 추천 코드는 사용할 수 없습니다.' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // referrals에 기록
      await client.query(
        'INSERT INTO referrals (referrer_uid, referred_uid) VALUES ($1, $2)',
        [referrerUid, req.uid],
      );

      // 추천인 티켓 +3
      await client.query(
        `INSERT INTO tickets (uid, balance, updated_at) VALUES ($1, 3, now())
         ON CONFLICT (uid) DO UPDATE SET balance = tickets.balance + 3, updated_at = now()`,
        [referrerUid],
      );
      const referrerBal = await client.query('SELECT balance FROM tickets WHERE uid = $1', [referrerUid]);
      await client.query(
        `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
         VALUES ($1, 'referral_bonus', 3, $2, $3)`,
        [referrerUid, referrerBal.rows[0].balance, `referral:${req.uid}`],
      );

      // 입력자 티켓 +3
      await client.query(
        `INSERT INTO tickets (uid, balance, updated_at) VALUES ($1, 3, now())
         ON CONFLICT (uid) DO UPDATE SET balance = tickets.balance + 3, updated_at = now()`,
        [req.uid],
      );
      const myBal = await client.query('SELECT balance FROM tickets WHERE uid = $1', [req.uid]);
      await client.query(
        `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
         VALUES ($1, 'referral_bonus', 3, $2, $3)`,
        [req.uid, myBal.rows[0].balance, `referral:${referrerUid}`],
      );

      await client.query('COMMIT');
      console.log(`[apply-referral] Referral bonus applied: referrer=${referrerUid}, referred=${req.uid}`);
      res.json({ applied: true });
    } catch (refErr) {
      await client.query('ROLLBACK');
      console.log(`[apply-referral] Referral failed: ${refErr.message}`);
      res.json({ applied: false, message: '추천 코드 적용 중 오류가 발생했습니다.' });
    } finally {
      client.release();
    }
  } catch (err) {
    console.error('[apply-referral] Error:', err);
    res.status(500).json({ error: '추천 코드 적용 중 오류가 발생했습니다.' });
  }
});

/**
 * GET /api/user/referral-code — 내 추천 코드 조회 (없으면 생성)
 */
router.get('/referral-code', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT referral_code FROM users WHERE uid = $1',
      [req.uid],
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: '유저 정보가 없습니다.' });
    }

    let code = rows[0].referral_code;
    if (!code) {
      code = generateReferralCode();
      for (let i = 0; i < 5; i++) {
        try {
          await pool.query(
            'UPDATE users SET referral_code = $1 WHERE uid = $2',
            [code, req.uid],
          );
          break;
        } catch {
          code = generateReferralCode();
        }
      }
    }

    res.json({ referralCode: code });
  } catch (err) {
    console.error('Get referral code error:', err);
    res.status(500).json({ error: '추천 코드 조회 중 오류가 발생했습니다.' });
  }
});

/**
 * GET /api/user/saju — 저장된 사주 조회
 */
router.get('/saju', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT birth_date, birth_time, gender FROM users WHERE uid = $1',
      [req.uid],
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: '저장된 사주 정보가 없습니다.' });
    }

    const row = rows[0];
    res.json({
      birthDate: row.birth_date,
      birthTime: row.birth_time,
      gender: row.gender,
    });
  } catch (err) {
    console.error('Get saju error:', err);
    res.status(500).json({ error: '사주 조회 중 오류가 발생했습니다.' });
  }
});

/**
 * GET /api/user/my-results — 저장된 모든 결과 조회
 */
router.get('/my-results', requireAuth, async (req, res) => {
  try {
    const results = await getUserResults(req.uid);
    res.json({ results });
  } catch (err) {
    console.error('Get my results error:', err);
    res.status(500).json({ error: '저장된 결과 조회 중 오류가 발생했습니다.' });
  }
});

/**
 * DELETE /api/user/account — 회원탈퇴 (모든 유저 데이터 삭제)
 */
router.delete('/account', requireAuth, async (req, res) => {
  try {
    const uid = req.uid;

    await pool.query('DELETE FROM referrals WHERE referrer_uid = $1 OR referred_uid = $1', [uid]);
    await pool.query('DELETE FROM ticket_transactions WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM tickets WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM compatibility_history WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM name_history WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM user_results WHERE uid = $1', [uid]);
    await pool.query('DELETE FROM users WHERE uid = $1', [uid]);

    res.json({ ok: true });
  } catch (err) {
    console.error('Delete account error:', err);
    res.status(500).json({ error: '계정 삭제 중 오류가 발생했습니다.' });
  }
});

export default router;
