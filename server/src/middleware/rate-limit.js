import { ipKeyGenerator, rateLimit } from 'express-rate-limit';

/**
 * Gemini를 호출하는 엔드포인트 전용 rate limit.
 *
 * 반드시 인증 미들웨어(requireAuth/optionalAuth) *뒤에* 붙일 것.
 * req.uid가 채워져 있어야 로그인 유저를 IP가 아닌 계정 단위로 센다.
 * (통신사 NAT 때문에 IP 하나에 수많은 사용자가 묶일 수 있다.)
 *
 * 익명은 무료인 오늘의 운세만 접근 가능하므로 한도를 더 낮게 잡는다.
 */
export const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: (req) => (req.uid ? 120 : 40),
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  keyGenerator: (req) => req.uid ?? ipKeyGenerator(req.ip),
  message: { error: '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.' },
});
