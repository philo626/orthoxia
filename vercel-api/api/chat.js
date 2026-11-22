/**
 * Orthoxia Patristic AI — Vercel Serverless Proxy (100% Free & Unblocked in Egypt)
 * --------------------------------------------------------------------------------
 * Keeps GEMINI_API_KEY & GROQ_API_KEY 100% hidden in Vercel Environment Variables.
 *
 * Endpoints (via vercel.json rewrites):
 *   - GET  / or /health or /api/chat  -> Safe health check & provider status
 *   - POST / or /v1/chat/completions or /api/chat -> OpenAI-compatible Orthodox AI chat
 */

const SYSTEM_GUARDRAIL =
  'أنت «المرشد الآبائي» داخل تطبيق «أرثوذكسيا» للكنيسة القبطية الأرثوذكسية. ' +
  'أجب باللغة العربية الفصحى الواضحة وبأسلوب روحي رصين وأمين تماماً لعقيدة وطقس الكنيسة القبطية الأرثوذكسية ' +
  '(الكتاب المقدس بترجمة فانديك، أقوال الآباء الأولين كالقديس أثناسيوس وكيرلس ويوحنا ذهبي الفم، والبابا شنودة الثالث، والأب متى المسكين). ' +
  'التزم بالدقة الكنسية الكاملة: لا تؤلّف آيات أو أقوالاً غير موجودة، وتجنّب تماماً أي تنسيق Markdown مثل النجوم (**) أو (***) أو (#). ' +
  'إذا سُئلت عن مسائل طلاق أو أحوال شخصية خاصة وجّه السائل بمحبة للرجوع لأب الاعتراف أو المجلس الإكليريكي. ' +
  'اجعل إجابتك مركّزة ومفيدة ومرتّبة في نقاط واضحة عند الحاجة.';

const RATE_WINDOW_MS = 10 * 60 * 1000;
const MAX_REQ_PER_WINDOW = 30;
const ipHits = new Map();

function checkRateLimit(ip) {
  const now = Date.now();
  const entry = ipHits.get(ip);
  if (!entry || now - entry.windowStart > RATE_WINDOW_MS) {
    if (ipHits.size > 2000) ipHits.clear();
    ipHits.set(ip, { count: 1, windowStart: now });
    return true;
  }
  if (entry.count >= MAX_REQ_PER_WINDOW) return false;
  entry.count += 1;
  return true;
}

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Orthoxia-Client');
  res.setHeader('Cache-Control', 'no-store');
}

let cachedDiscoveredModel = null;
let cachedDiscoveredAt = 0;

async function discoverLatestFlashModel(apiKey) {
  const now = Date.now();
  if (cachedDiscoveredModel && now - cachedDiscoveredAt < 3600_000) {
    return cachedDiscoveredModel;
  }
  try {
    const resp = await fetch('https://generativelanguage.googleapis.com/v1beta/models', {
      headers: { 'x-goog-api-key': apiKey },
    });
    if (!resp.ok) return null;
    const data = await resp.json();
    const list = Array.isArray(data?.models) ? data.models : [];
    const usable = list
      .filter(
        (m) =>
          Array.isArray(m.supportedGenerationMethods) &&
          m.supportedGenerationMethods.includes('generateContent') &&
          typeof m.name === 'string' &&
          m.name.includes('gemini') &&
          m.name.includes('flash') &&
          !m.name.includes('image') &&
          !m.name.includes('tts') &&
          !m.name.includes('audio') &&
          !m.name.includes('thinking'),
      )
      .map((m) => m.name.replace(/^models\//, ''));
    if (usable.length > 0) {
      // Prefer highest version number (descending lexicographical works cleanly for gemini-3.8 > gemini-3.5 > gemini-2.5)
      usable.sort().reverse();
      cachedDiscoveredModel = usable[0];
      cachedDiscoveredAt = now;
      return cachedDiscoveredModel;
    }
  } catch (_) {}
  return null;
}

async function callGemini(apiKey, userMessages) {
  const contents = [];

  for (const m of userMessages) {
    const role = m.role === 'assistant' ? 'model' : 'user';
    const text = String(m.content || '').trim();
    if (!text) continue;
    contents.push({
      role,
      parts: [{ text: text.slice(0, 4000) }],
    });
  }

  if (contents.length === 0) return null;

  const payload = JSON.stringify({
    system_instruction: { parts: [{ text: SYSTEM_GUARDRAIL }] },
    contents,
    generationConfig: {
      temperature: 0.25,
      maxOutputTokens: 1024,
    },
  });

  const candidateModels = [
    ...(cachedDiscoveredModel ? [cachedDiscoveredModel] : []),
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-flash-latest',
    'gemini-2.5-flash',
  ];

  const tried = new Set();
  const errors = [];

  async function tryModel(model) {
    if (!model || tried.has(model)) return null;
    tried.add(model);
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
      const resp = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: payload,
      });

      if (resp.ok) {
        const data = await resp.json();
        const parts = data?.candidates?.[0]?.content?.parts || [];
        const text = parts
          .map((p) => (typeof p?.text === 'string' ? p.text : ''))
          .join('\n')
          .trim();
        if (text) return { text, model };
      } else {
        let msg = '';
        try {
          const errJson = await resp.json();
          msg = String(errJson?.error?.message || '').slice(0, 140);
        } catch (_) {}
        errors.push(`${model}:${resp.status}(${msg})`);
      }
    } catch (_) {
      errors.push(`${model}:net`);
    }
    return null;
  }

  for (const model of candidateModels) {
    const hit = await tryModel(model);
    if (hit) return hit;
  }

  // Future-proof auto-discovery: query Google's active models list if static names change again
  const discovered = await discoverLatestFlashModel(apiKey);
  if (discovered) {
    const hit = await tryModel(discovered);
    if (hit) return hit;
  }

  return { error: errors.join(' | ') };
}

async function callGroq(apiKey, userMessages) {
  const messages = [{ role: 'system', content: SYSTEM_GUARDRAIL }];
  for (const m of userMessages) {
    const role = m.role === 'assistant' ? 'assistant' : 'user';
    const content = String(m.content || '').trim();
    if (!content) continue;
    messages.push({ role, content: content.slice(0, 4000) });
  }

  try {
    const resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages,
        temperature: 0.25,
        max_tokens: 1024,
      }),
    });

    if (resp.ok) {
      const data = await resp.json();
      const text = String(data?.choices?.[0]?.message?.content || '').trim();
      if (text) return { text, model: 'llama-3.3-70b-versatile' };
    }
  } catch (_) {}
  return null;
}

export default async function handler(req, res) {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  const geminiKey = (process.env.GEMINI_API_KEY || '').trim();
  const groqKey = (process.env.GROQ_API_KEY || '').trim();
  const hasGemini = geminiKey.length > 10;
  const hasGroq = groqKey.length > 10;

  if (req.method === 'GET') {
    return res.status(200).json({
      status: 'ok',
      service: 'orthoxia-patristic-ai',
      host: 'vercel',
      providers: {
        gemini: hasGemini,
        groq: hasGroq,
      },
    });
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Optional App Client Lock
  const expectedAppKey = (process.env.APP_CLIENT_KEY || '').trim();
  if (expectedAppKey) {
    const sentHeader = String(req.headers['x-orthoxia-client'] || '').trim();
    const authBearer = String(req.headers['authorization'] || '')
      .replace(/^Bearer\s+/i, '')
      .trim();
    if (sentHeader !== expectedAppKey && authBearer !== expectedAppKey) {
      return res.status(401).json({ error: 'Unauthorized client' });
    }
  }

  // Per-IP Rate Limit
  const forwardedFor = String(req.headers['x-forwarded-for'] || '').split(',')[0].trim();
  const clientIp = forwardedFor || req.socket?.remoteAddress || 'unknown';
  if (!checkRateLimit(clientIp)) {
    return res.status(429).json({
      error: 'تم تجاوز الحد المسموح مؤقتاً. يُرجى المحاولة بعد دقائق قليلة.',
    });
  }

  const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
  const rawMessages = Array.isArray(body?.messages) ? body.messages : [];
  const safeMessages = rawMessages
    .filter((m) => m && (m.role === 'user' || m.role === 'assistant'))
    .slice(-10);

  if (safeMessages.length === 0) {
    return res.status(400).json({ error: 'No user message provided' });
  }

  if (!hasGemini && !hasGroq) {
    return res.status(503).json({
      error: 'No AI provider secret configured on Vercel yet (add GEMINI_API_KEY or GROQ_API_KEY).',
    });
  }

  let result = null;
  let usedProvider = '';
  let geminiDiag = '';

  if (hasGemini) {
    const g = await callGemini(geminiKey, safeMessages);
    if (g && g.text) {
      result = g;
      usedProvider = 'gemini';
    } else if (g && g.error) {
      geminiDiag = g.error;
    }
  }

  if (!result && hasGroq) {
    const q = await callGroq(groqKey, safeMessages);
    if (q && q.text) {
      result = q;
      usedProvider = 'groq';
    }
  }

  if (!result) {
    return res.status(502).json({
      error: 'تعذر الحصول على إجابة من مزود الذكاء الاصطناعي حالياً.',
      detail: geminiDiag || 'provider_unavailable',
    });
  }

  return res.status(200).json({
    id: `orthoxia-${Date.now()}`,
    object: 'chat.completion',
    provider: usedProvider,
    model: result.model,
    choices: [
      {
        index: 0,
        message: {
          role: 'assistant',
          content: result.text,
        },
        finish_reason: 'stop',
      },
    ],
  });
}
