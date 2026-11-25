/**
 * Orthoxia Patristic AI — Vercel Serverless Proxy (100% Free & Unblocked in Egypt)
 * --------------------------------------------------------------------------------
 * Keeps GEMINI_API_KEY & GROQ_API_KEY 100% hidden server-side.
 * Bulletproof 2026 routing:
 *   1) Auto-discovers ALL active chat models from Google's live catalog
 *      (filtering out deprecated 2.0/2.5/gemma-3 and non-chat transcribe/tts/image/live models).
 *   2) Races 6 diverse active models simultaneously (Gemini 3.5/3.6/4 + Flash-Lite + Gemma 4)
 *      with a generous 15s window so thinking models finish cleanly instead of timing out at 7s.
 *   3) Cooldown cache avoids re-hitting 400/404/429 models on warm instances.
 *   4) Optional automatic Groq fallback if GROQ_API_KEY is configured.
 */

const SYSTEM_GUARDRAIL =
  'أنت «المرشد الآبائي القبطي الأرثوذكسي» داخل تطبيق «أرثوذكسيا» للكنيسة القبطية الأرثوذكسية. ' +
  'أجب بدقة لاهوتية وكتابية وطقسية وأمينة ١٠٠٪ لعقيدة وطقس الكنيسة القبطية الأرثوذكسية فقط ' +
  '(الكتاب المقدس بترجمة فاندايك، أقوال الآباء الأولين كالقديس أثناسيوس الرسولي والقديس كيرلس الكبير والقديس يوحنا ذهبي الفم، ' +
  'والآباء المعاصرين مثل قداسة البابا شنودة الثالث، القمص تادرس يعقوب ملطي، القمص أنطونيوس فكري، والأب متى المسكين). ' +
  'قواعد صارمة لا تحيد عنها: ' +
  '١) أجب مباشرة على سؤال المستخدم بالضبط — لا تغيّر الموضوع ولا تذكر قصصاً غير مرتبطة بالسؤال. ' +
  '٢) إذا سألك المستخدم بالعامية المصرية، رد عليه بأسلوب دافئ وقريب ومفهوم يجمع بين بساطة العامية المصرية المحترمة ووقار الكنيسة، مع وضع الآيات الكتابية وأقوال الآباء بنصها الصحيح بين «...». ' +
  '٣) التزم بالحقائق القبطية الأرثوذكسية بدقة (الأسرار السبعة، الصوم الكبير ٥٥ يوماً، صوم يونان ٣ أيام قبل الصوم الكبير بأسبوعين، الشفاعة التوسلية للقديسين، التناول هو جسد الرب ودمه الحقيقيان). ' +
  '٤) لا تؤلف آيات أو أرقام إصحاحات أو أقوالاً غير متأكد منها أبداً. ' +
  '٥) ممنوع استخدام رموز الماركداون مثل (**) أو (***) أو (#). رتب إجابتك في نقاط واضحة (١. ٢. ٣.) أو (•) وبشكل مركّز ومفيد. ' +
  '٦) في مسائل الطلاق أو الأحوال الشخصية الخاصة، وجّه السائل بمحبة للرجوع لأب الاعتراف أو المجلس الإكليريكي.';

const RATE_WINDOW_MS = 10 * 60 * 1000;
const MAX_REQ_PER_WINDOW = 50;
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

let cachedModelList = null;
let cachedModelsAt = 0;
let lastWorkingModel = null;

// Cooldown map so 429/400/404 models aren't hammered repeatedly on the same warm instance
const modelCooldownUntil = new Map();

function isOnCooldown(model) {
  const until = modelCooldownUntil.get(model) || 0;
  return Date.now() < until;
}

function markCooldown(model, status) {
  const ms = status === 400 || status === 404 ? 900_000 : status === 429 ? 120_000 : 15_000;
  modelCooldownUntil.set(model, Date.now() + ms);
}

/**
 * Discovers ALL active 2026 chat models available to this API key,
 * filtering out deprecated 2.0/2.5/gemma-3 and non-chat models.
 */
async function discoverActiveModels(apiKey) {
  const now = Date.now();
  if (cachedModelList && now - cachedModelsAt < 1800_000) {
    return cachedModelList;
  }
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 4500);
    let resp;
    try {
      resp = await fetch('https://generativelanguage.googleapis.com/v1beta/models', {
        headers: { 'x-goog-api-key': apiKey },
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }
    if (!resp.ok) return [];
    const data = await resp.json();
    const list = Array.isArray(data?.models) ? data.models : [];

    const bannedSubstrings = [
      '2.0',
      '2.5',
      'gemma-3',
      'image',
      'tts',
      'audio',
      'vision',
      'embedding',
      'robotics',
      'computer-use',
      'deep-research',
      'omni',
      'transcribe',
      'live',
      'aqa',
      'veo',
      'lyria',
      'imagen',
      'learnlm',
      'shield',
      'medgemma',
      'translate',
      'nano',
      'pro',
    ];

    const filtered = list
      .filter((m) => {
        if (!Array.isArray(m.supportedGenerationMethods)) return false;
        if (!m.supportedGenerationMethods.includes('generateContent')) return false;
        const name = String(m.name || '').toLowerCase();
        if (!name.includes('gemini') && !name.includes('gemma')) return false;
        if (bannedSubstrings.some((b) => name.includes(b))) return false;
        return true;
      })
      .map((m) => String(m.name).replace(/^models\//, ''));

    cachedModelList = filtered;
    cachedModelsAt = now;
    return filtered;
  } catch (_) {
    return [];
  }
}

/**
 * Builds a high-reliability candidate list from live discovered models only.
 * Batch 1 (6 models in parallel) covers Gemini 3.5 Flash, 3.6 Flash, 3.5 Flash-Lite,
 * Gemma 4 31B, Gemini 4, and Flash-Latest so whichever responds first wins!
 */
function buildCandidateModels(discovered) {
  const fallbackDefaults = [
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-3.6-flash',
    'gemma-4-31b-it',
    'gemma-4-26b-a4b-it',
    'gemini-3-flash-preview',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
  ];

  const pool = Array.from(new Set([...discovered, ...fallbackDefaults]));

  function rank(m) {
    const n = m.toLowerCase();
    // Put proven fast models & distinct families in Batch 1 (top 6)
    if (n === 'gemini-3.5-flash-lite') return 1;
    if (n === 'gemini-3.5-flash') return 2;
    if (n === 'gemma-4-31b-it') return 3;
    if (n === 'gemini-3.6-flash') return 4;
    if (n === 'gemini-4-argon') return 5;
    if (n === 'gemini-3-flash-preview') return 6;
    // Batch 2 (next 6)
    if (n === 'gemini-4-neon') return 7;
    if (n === 'gemma-4-26b-a4b-it') return 8;
    if (n === 'gemini-3.1-flash-lite') return 9;
    if (n === 'gemini-4-hydrogen') return 10;
    if (n === 'gemini-4-carbon') return 11;
    if (n === 'gemini-3.1-flash-lite-preview') return 12;
    if (n === 'gemini-flash-latest') return 13;
    if (n === 'gemini-flash-lite-latest') return 14;
    if (n === 'gemini-3.7-flash') return 18;
    if (n === 'gemini-3.8-flash') return 19;
    return 20;
  }

  pool.sort((a, b) => rank(a) - rank(b));

  const ordered = [];
  if (lastWorkingModel && !isOnCooldown(lastWorkingModel)) {
    ordered.push(lastWorkingModel);
  }
  for (const m of pool) ordered.push(m);

  const unique = Array.from(new Set(ordered));
  const ready = unique.filter((m) => !isOnCooldown(m));
  const cooling = unique.filter((m) => isOnCooldown(m));
  return [...ready, ...cooling];
}

async function callGemini(apiKey, userMessages) {
  const cleanMsgs = [];
  for (const m of userMessages) {
    const role = m.role === 'assistant' ? 'model' : 'user';
    const text = String(m.content || '').trim();
    if (!text) continue;
    cleanMsgs.push({ role, text: text.slice(0, 3500) });
  }
  if (cleanMsgs.length === 0) return null;

  const discovered = await discoverActiveModels(apiKey);
  const candidateModels = buildCandidateModels(discovered);
  const errors = [];

  async function invokeOnce(model, timeoutMs) {
    const isGemma = model.toLowerCase().startsWith('gemma');
    let bodyObj;

    if (isGemma) {
      const contents = cleanMsgs.map((m, i) => ({
        role: m.role,
        parts: [
          {
            text:
              i === 0 && m.role === 'user'
                ? `تعليمات النظام:\n${SYSTEM_GUARDRAIL}\n\nسؤال المستخدم:\n${m.text}`
                : m.text,
          },
        ],
      }));
      bodyObj = {
        contents,
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 1024,
        },
      };
    } else {
      const contents = cleanMsgs.map((m) => ({
        role: m.role,
        parts: [{ text: m.text }],
      }));
      bodyObj = {
        system_instruction: { parts: [{ text: SYSTEM_GUARDRAIL }] },
        contents,
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 1200,
        },
      };
    }

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const resp = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: JSON.stringify(bodyObj),
        signal: controller.signal,
      });

      if (resp.ok) {
        const data = await resp.json();
        const parts = data?.candidates?.[0]?.content?.parts || [];
        const text = parts
          .filter((p) => !p?.thought && typeof p?.text === 'string')
          .map((p) => p.text)
          .join('\n')
          .trim();
        if (text.length >= 12) return { ok: true, text, model };
        return { ok: false, status: 200, msg: 'empty_response' };
      }

      let msg = '';
      try {
        const errJson = await resp.json();
        msg = String(errJson?.error?.message || '').slice(0, 90);
      } catch (_) {}
      markCooldown(model, resp.status);
      return { ok: false, status: resp.status, msg };
    } catch (err) {
      const isAbort = err && err.name === 'AbortError';
      return {
        ok: false,
        status: isAbort ? 408 : 500,
        msg: isAbort ? 'timeout' : String(err?.message || 'net_err').slice(0, 60),
      };
    } finally {
      clearTimeout(timer);
    }
  }

  // Race 6 diverse models in parallel per batch (Batch 1: 15s, Batch 2: 11s -> fits inside Vercel 30s limit!)
  const batches = [
    { models: candidateModels.slice(0, 6), timeoutMs: 15000 },
    { models: candidateModels.slice(6, 12), timeoutMs: 11000 },
  ];

  for (const b of batches) {
    if (b.models.length === 0) continue;
    try {
      const winner = await Promise.any(
        b.models.map(async (model) => {
          const r = await invokeOnce(model, b.timeoutMs);
          if (r.ok) return r;
          errors.push(`${model}:${r.status}(${r.msg})`);
          throw new Error(`${model}:${r.status}`);
        }),
      );
      lastWorkingModel = winner.model;
      return { text: winner.text, model: winner.model };
    } catch (_) {
      // Whole batch failed -> try next batch immediately
    }
  }

  return { error: errors.join(' | ') };
}

async function callGroq(apiKey, userMessages) {
  const messages = [{ role: 'system', content: SYSTEM_GUARDRAIL }];
  for (const m of userMessages) {
    const role = m.role === 'assistant' ? 'assistant' : 'user';
    const content = String(m.content || '').trim();
    if (!content) continue;
    messages.push({ role, content: content.slice(0, 3500) });
  }

  for (const model of ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant']) {
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 8000);
      let resp;
      try {
        resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${apiKey}`,
          },
          body: JSON.stringify({
            model,
            messages,
            temperature: 0.25,
            max_tokens: 1024,
          }),
          signal: controller.signal,
        });
      } finally {
        clearTimeout(timer);
      }

      if (resp.ok) {
        const data = await resp.json();
        const text = String(data?.choices?.[0]?.message?.content || '').trim();
        if (text) return { text, model };
      }
    } catch (_) {}
  }
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
    const discovered = hasGemini ? await discoverActiveModels(geminiKey) : [];
    const candidates = hasGemini ? buildCandidateModels(discovered) : [];
    return res.status(200).json({
      status: 'ok',
      service: 'orthoxia-patristic-ai',
      version: 'v4-fast-race',
      host: 'vercel',
      providers: {
        gemini: hasGemini,
        groq: hasGroq,
      },
      lastWorkingModel,
      discoveredModels: discovered,
      candidateOrder: candidates.slice(0, 12),
    });
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

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
