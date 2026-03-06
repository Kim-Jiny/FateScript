import admin from '../config/firebase.js';

/**
 * 선택적 인증 — 토큰이 있으면 uid를 추출하고, 없으면 그냥 통과
 */
export async function optionalAuth(req, _res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    req.uid = null;
    return next();
  }

  try {
    const token = header.slice(7);
    const decoded = await admin.auth().verifyIdToken(token);
    req.uid = decoded.uid;
    req.userEmail = decoded.email ?? null;
  } catch {
    req.uid = null;
  }
  next();
}

/**
 * 필수 인증 — 토큰이 유효하지 않으면 401 반환
 */
export async function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: '인증이 필요합니다.' });
  }

  try {
    const token = header.slice(7);
    const decoded = await admin.auth().verifyIdToken(token);
    req.uid = decoded.uid;
    req.userEmail = decoded.email ?? null;
    next();
  } catch {
    res.status(401).json({ error: '유효하지 않은 인증 토큰입니다.' });
  }
}
