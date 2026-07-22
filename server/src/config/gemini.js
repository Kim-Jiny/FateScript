import 'dotenv/config';
import { GoogleGenAI } from '@google/genai';

const apiKey = process.env.GEMINI_API_KEY?.trim();

if (!apiKey) {
  throw new Error('[Gemini] GEMINI_API_KEY is not set.');
}

const ai = new GoogleGenAI({ apiKey });

export default ai;
