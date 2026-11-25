/**
 * Orthoxia Patristic AI — Vercel Serverless Proxy (100% Free & Unblocked in Egypt)
 * --------------------------------------------------------------------------------
 * Keeps GEMINI_API_KEY & GROQ_API_KEY 100% hidden in Vercel Environment Variables.
 * Resilient multi-model routing:
 *   1) Auto-discovers active stable Gemini & Gemma models from Google's live catalog
 *      (filtering out quota-0 preview/omni/tts/image models)
 *   2) Automatically retries transient 503 spikes and gracefully falls back across
 *      Gemini Flash + Gemma 3 27B/12B (which have generous free quotas & high uptime)
 *   3) Optional Groq fallback if GROQ_API_KEY is also configured
 */

const SYSTEM_GUARDRAIL =
  'أنت «المرشد الآبائي القبطي الأرثوذكسي» داخل تطبيق «أرثوذكسيا» للكنيسة القبطية الأرثوذكسية. ' +
  'أجب بدقة لاهوتية وكتابية وطقسية وأمينة ١٠٠٪ لعقيدة وطقس الكنيسة القبطية الأرثوذكسية فقط ' +
  '(الكتاب المقدس بترجمة فاندايك، أقوال الآباء الأولين كالقديس أثناسيوس الرسولي والقديس كيرلس الكبير والقديس يوحنا ذهبي الفم، ' +
  'والآباء المعاصرين مثل قداسة البابا شنودة الثالث، القمص تادرس يعقوب ملطي، القمص أنطونيوس فكري، والأب متى المسكين). ' +
  'قواعد صارمة لا تحيد عنها: ' +
  '١) أجب مباشرة على سؤال المستخدم بالضبط — لا تغيّر الموضوع ولا تذكر قصصاً غير مرتبطة بالسؤال. ' +
  '٢) إذا سألك المستخدم بالعامية المصرية، رد عليه بأسلوب دافئ وقريب ومفهوم يجمع بين بساطة العامية المصرية المحترمة ووقار الكنيسة، مع وضع الآيات الكتابية وأقوال الآباء بنصها الصحيح بين «...». ' +
  '٣) التزم بالحقائق القبطية الأرثوذكسية بدقة (الأسرار السبعة، الصوم الكبير ٥٥ يوماً، صوم يونان ٣ أيام، الشفاعة التوسلية للقديسين، التناول هو جسد الرب ودمه الحقيقيان). ' +
  '٤) لا تؤلف آيات أو أرقام إصحاحات أو أقوالاً غير متأكد منها أبداً. ' +
  '٥) ممنوع استخدام رموز الماركداون مثل (**) أو (***) أو (#). رتب إجابتك في نقاط واضحة (١. ٢. ٣.) أو (•). ' +
  '٦) في مسائل الطلاق أو الأحوال الشخصية الخاصة، وجّه السائل بمحبة للرجوع لأب الاعتراف أو المجلس الإكليريكي.';

const RATE_WINDOW_MS = 10 * 60 * 1000;
const MAX_REQ_PER_WINDOW = 40;
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

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let cachedModelList = null;
let cachedModelsAt = 0;
let lastWorkingModel = null;

/**
 * Discovers ALL active text-generation models available to this API key,
 * strictly prioritizing fast stable flash-lite / gemma models and demoting preview/omni models.
 */
async function discoverActiveModels(apiKey) {
  const now = Date.now();
  if (cachedModelList && now - cachedModelsAt < 1800_000) {
    return cachedModelList;
  }
  try {
    const resp = await fetch('https://generativelanguage.googleapis.com/v1beta/models', {
      headers: { 'x-goog-api-key': apiKey },
    });
    if (!resp.ok) return [];
    const data = await resp.json();
    const list = Array.isArray(data?.models) ? data.models : [];

    const filtered = list
      .filter((m) => {
        if (!Array.isArray(m.supportedGenerationMethods)) return false;
        if (!m.supportedGenerationMethods.includes('generateContent')) return false;
        const name = String(m.name || '').toLowerCase();
        if (!name.includes('gemini') && !name.includes('gemma')) return false;
        if (
          name.includes('image') ||
          name.includes('tts') ||
          name.includes('audio') ||
          name.includes('vision') ||
          name.includes('embedding') ||
          name.includes('robotics') ||
          name.includes('computer-use') ||
          name.includes('deep-research') ||
          name.includes('omni')
        ) {
          return false;
        }
        return true;
      })
      .map((m) => String(m.name).replace(/^models\//, ''));

    // Score models: stable gemini flash > gemma-3-27b/12b > other stable gemini > preview
    function rank(name) {
      const n = name.toLowerCase();
      if (n.includes('preview') || n.includes('exp')) return 90;
      if (n.includes('2.5') || n.includes('2.0')) return 85; // deprecated for new keys
      if (n.startsWith('gemini-3.5-flash-lite')) return 10;
      if (n.startsWith('gemini-3.1-flash-lite')) return 12;
      if (n.startsWith('gemini-3.7-flash')) return 14;
      if (n.startsWith('gemini-3.6-flash')) return 16;
      if (n.startsWith('gemini-3.5-flash')) return 18;
      if (n.startsWith('gemini-3.8-flash')) return 20;
      if (n.startsWith('gemma-4')) return 24;
      if (n.includes('flash')) return 30;
      if (n.startsWith('gemini-')) return 40;
      if (n.startsWith('gemma-')) return 50;
      return 70;
    }

    filtered.sort((a, b) => rank(a) - rank(b) || b.localeCompare(a));
    cachedModelList = filtered;
    cachedModelsAt = now;
    return filtered;
  } catch (_) {
    return [];
  }
}

async function callGemini(apiKey, userMessages) {
  const cleanMsgs = [];
  for (const m of userMessages) {
    const role = m.role === 'assistant' ? 'model' : 'user';
    const text = String(m.content || '').trim();
    if (!text) continue;
    cleanMsgs.push({ role, text: text.slice(0, 4000) });
  }
  if (cleanMsgs.length === 0) return null;

  const discovered = await discoverActiveModels(apiKey);
  const activeOnly = discovered.filter(
    (m) => !m.includes('2.5') && !m.includes('2.0') && !m.includes('preview') && !m.includes('exp'),
  );
  const candidateModels = [
    ...(lastWorkingModel ? [lastWorkingModel] : []),
    ...activeOnly,
    'gemini-3.5-flash-lite',
    'gemini-3.7-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.8-flash',
    'gemma-4-31b-it',
    'gemma-4-26b-a4b-it',
  ];

  const tried = new Set();
  const errors = [];

  async function invokeOnce(model) {
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
          temperature: 0.25,
          maxOutputTokens: 900,
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
          temperature: 0.25,
          maxOutputTokens: 900,
        },
      };
    }

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 7500);
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
          .map((p) => (typeof p?.text === 'string' ? p.text : ''))
          .join('\n')
          .trim();
        if (text) return { ok: true, text, model };
        return { ok: false, status: 200, msg: 'empty_response' };
      }

      let msg = '';
      try {
        const errJson = await resp.json();
        msg = String(errJson?.error?.message || '').slice(0, 120);
      } catch (_) {}
      return { ok: false, status: resp.status, msg };
    } finally {
      clearTimeout(timer);
    }
  }

  // Race models in parallel batches of 3 for sub-2s response even during single-model 503 spikes!
  const uniqueModels = [];
  for (const m of candidateModels) {
    if (m && !uniqueModels.includes(m)) uniqueModels.push(m);
  }

  for (let i = 0; i < Math.min(uniqueModels.length, 9); i += 3) {
    const batch = uniqueModels.slice(i, i + 3);
    try {
      const winner = await Promise.any(
        batch.map(async (model) => {
          const r = await invokeOnce(model);
          if (r.ok) return r;
          errors.push(`${model}:${r.status}(${r.msg})`);
          throw new Error(`${model}:${r.status}`);
        }),
      );
      lastWorkingModel = winner.model;
      return { text: winner.text, model: winner.model };
    } catch (_) {
      // Whole batch failed -> proceed immediately to next batch
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
    const discovered = hasGemini ? await discoverActiveModels(geminiKey) : [];
    return res.status(200).json({
      status: 'ok',
      service: 'orthoxia-patristic-ai',
      host: 'vercel',
      providers: {
        gemini: hasGemini,
        groq: hasGroq,
      },
      discoveredModels: discovered.slice(0, 8),
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
