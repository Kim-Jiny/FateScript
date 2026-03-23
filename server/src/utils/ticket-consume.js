import pool from '../config/db.js';

export const TICKET_COST = {
  daily: 0,
  fortune: 1,
  name_analyze: 1,
  name_recommend: 1,
  compatibility: 1,
  auspicious_date: 1,
  team_compatibility: 1,
};

/**
 * 서비스 엔드포인트 내에서 티켓을 원자적으로 차감.
 * @returns {{ success: boolean, balance: number, required?: number }}
 */
export async function consumeTicketForService(uid, type) {
  const cost = TICKET_COST[type];
  if (cost === undefined) throw new Error(`Unknown ticket type: ${type}`);
  if (cost === 0) return { success: true, balance: -1 };

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      'SELECT balance FROM tickets WHERE uid = $1 FOR UPDATE',
      [uid],
    );
    const currentBalance = rows.length > 0 ? rows[0].balance : 0;

    if (currentBalance < cost) {
      await client.query('ROLLBACK');
      return { success: false, balance: currentBalance, required: cost };
    }

    const newBalance = currentBalance - cost;
    await client.query(
      'UPDATE tickets SET balance = $1, updated_at = now() WHERE uid = $2',
      [newBalance, uid],
    );
    await client.query(
      `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
       VALUES ($1, 'consume', $2, $3, $4)`,
      [uid, -cost, newBalance, type],
    );

    await client.query('COMMIT');
    return { success: true, balance: newBalance };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 서비스 실패 시 티켓 환불. consume의 역연산.
 */
export async function refundTicketForService(uid, type) {
  const cost = TICKET_COST[type];
  if (!cost) return;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `INSERT INTO tickets (uid, balance, updated_at) VALUES ($1, $2, now())
       ON CONFLICT (uid) DO UPDATE SET balance = tickets.balance + $2, updated_at = now()`,
      [uid, cost],
    );
    const { rows } = await client.query('SELECT balance FROM tickets WHERE uid = $1', [uid]);
    const newBalance = rows[0].balance;

    await client.query(
      `INSERT INTO ticket_transactions (uid, type, amount, balance_after, ref_id)
       VALUES ($1, 'consume_refund', $2, $3, $4)`,
      [uid, cost, newBalance, `refund:${type}`],
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Ticket refund failed:', err);
  } finally {
    client.release();
  }
}
