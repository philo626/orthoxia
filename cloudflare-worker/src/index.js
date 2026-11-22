/**
 * Orthoxia Patristic AI — Hardened Cloudflare Worker Proxy
 * --------------------------------------------------------
 * Keeps your Google Gemini & Groq API keys 100% hidden server-side (Cloudflare Secrets).
 * Every user of the Orthoxia APK gets instant Coptic Orthodox AI with zero API key setup.
 *
 * Supported Secrets (set in Cloudflare Dashboard -> Settings -> Variables and Secrets):
 *   - GEMINI_API_KEY   (Primary — Free tier at https://aistudio.google.com/apikey)
 *   - GROQ_API_KEY     (Optional automatic fallback — Free tier at https://console.groq.com/keys)
 *   - APP_CLIENT_KEY   (Optional extra lock — must match X-Orthoxia-Client header if set)
 *
 * Endpoints:
 *   - GET  /health               -> Health check & active provider status (never leaks keys)
 *   - POST / or /v1/chat/completions -> OpenAI-compatible chat endpoint for Orthoxia app
 */

const SYSTEM_GUARDRAIL =
  'أنت «المرشد الآبائي» داخل تطبيق «أرثوذكسيا» للكنيسة القبطية الأرثوذكسية. ' +
  'أجب باللغة العربية الفصحى الواضحة وبأسلوب روحي رصين وأمين تماماً لعقيدة وطقس الكنيسة القبطية الأرثوذكسية ' +
  '(الكتاب المقدس بترجمة فانديك، أقوال الآباء الأولين كالقديس أثناسيوس وكيرلس ويوحنا ذهبي الفم، والبابا شنودة الثالث، والأب متى المسكين). ' +
  'التزم بالدقة الكنسية الكاملة: لا تؤلّف آيات أو أقوالاً غير موجودة، وتجنّب تماماً أي تنسيق Markdown مثل النجوم (**) أو (***) أو (#). ' +
  'إذا سُئلت عن مسائل طلاق أو أحوال شخصية خاصة وجّه السائل بمحبة للرجوع لأب الاعتراف أو المجلس الإكليريكي. ' +
  'اجعل إجابتك مركّزة ومفيدة ومرتّبة في نقاط واضحة عند الحاجة.';

// Lightweight in-isolate IP rate limiter (per Cloudflare edge PoP)
const RATE_WINDOW_MS = 10 * 60 * 1000; // 10 minutes
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
  if (entry.count >= MAX_REQ_PER_WINDOW) {
    return false;
  }
  entry.count += 1;
  return true;
}

function jsonResponse(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Orthoxia-Client',
      'Cache-Control': 'no-store',
    },
  });
}

async function callGemini(apiKey, userMessages) {
  const models = ['gemini-2.5-flash', 'gemini-2.0-flash'];
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

  // Supports both classic AIza... keys (AI Studio) and modern 2026 AQ.... keys (AI Studio + Vertex Express)
  for (const model of models) {
    const endpoints = [
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`,
      `https://aiplatform.googleapis.com/v1/publishers/google/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`,
    ];

    for (const url of endpoints) {
      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: payload,
        });

        if (res.ok) {
          const data = await res.json();
          const parts = data?.candidates?.[0]?.content?.parts || [];
          const text = parts
            .map((p) => (typeof p?.text === 'string' ? p.text : ''))
            .join('\n')
            .trim();
          if (text) return { text, model };
        }
      } catch (_) {}
    }
  }
  return null;
}

async function callGroq(apiKey, userMessages) {
  const messages = [{ role: 'system', content: SYSTEM_GUARDRAIL }];
  for (const m of userMessages) {
    const role = m.role === 'assistant' ? 'assistant' : 'user';
    const content = String(m.content || '').trim();
    if (!content) continue;
    messages.push({ role, content: content.slice(0, 4000) });
  }

  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
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

  if (res.ok) {
    const data = await res.json();
    const text = String(data?.choices?.[0]?.message?.content || '').trim();
    if (text) return { text, model: 'llama-3.3-70b-versatile' };
  }
  return null;
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Orthoxia-Client',
        },
      });
    }

    const url = new URL(request.url);
    const hasGemini = Boolean(env.GEMINI_API_KEY && env.GEMINI_API_KEY.trim().length > 10);
    const hasGroq = Boolean(env.GROQ_API_KEY && env.GROQ_API_KEY.trim().length > 10);

    // 1. Health Endpoint (Safe public check — never exposes secrets)
    if (request.method === 'GET' && (url.pathname === '/health' || url.pathname === '/')) {
      return jsonResponse({
        status: 'ok',
        service: 'orthoxia-patristic-ai',
        providers: {
          gemini: hasGemini,
          groq: hasGroq,
        },
      });
    }

    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    // 2. Optional App Client Lock (protects against random external scraping)
    const expectedAppKey = (env.APP_CLIENT_KEY || '').trim();
    if (expectedAppKey) {
      const sentHeader = (request.headers.get('X-Orthoxia-Client') || '').trim();
      const authBearer = (request.headers.get('Authorization') || '')
        .replace(/^Bearer\s+/i, '')
        .trim();
      if (sentHeader !== expectedAppKey && authBearer !== expectedAppKey) {
        return jsonResponse({ error: 'Unauthorized client' }, 401);
      }
    }

    // 3. Per-IP Rate Limit
    const clientIp = request.headers.get('CF-Connecting-IP') || 'unknown';
    if (!checkRateLimit(clientIp)) {
      return jsonResponse(
        { error: 'تم تجاوز الحد المسموح مؤقتاً. يُرجى المحاولة بعد دقائق قليلة.' },
        429,
      );
    }

    // 4. Validate Payload
    let body;
    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: 'Invalid JSON payload' }, 400);
    }

    const rawMessages = Array.isArray(body?.messages) ? body.messages : [];
    // Filter out any external system prompts — enforce server-side Orthodox guardrail ONLY
    const safeMessages = rawMessages
      .filter((m) => m && (m.role === 'user' || m.role === 'assistant'))
      .slice(-10);

    if (safeMessages.length === 0) {
      return jsonResponse({ error: 'No user message provided' }, 400);
    }

    if (!hasGemini && !hasGroq) {
      return jsonResponse(
        { error: 'No AI provider secret configured on Cloudflare Worker yet.' },
        503,
      );
    }

    // 5. Primary: Google Gemini -> Automatic Fallback: Groq
    let result = null;
    let usedProvider = '';

    if (hasGemini) {
      try {
        result = await callGemini(env.GEMINI_API_KEY.trim(), safeMessages);
        if (result) usedProvider = 'gemini';
      } catch (_) {}
    }

    if (!result && hasGroq) {
      try {
        result = await callGroq(env.GROQ_API_KEY.trim(), safeMessages);
        if (result) usedProvider = 'groq';
      } catch (_) {}
    }

    if (!result) {
      return jsonResponse(
        { error: 'تعذر الحصول على إجابة من مزود الذكاء الاصطناعي حالياً. حاول مرة أخرى بعد قليل.' },
        502,
      );
    }

    // Return standard OpenAI-compatible payload expected by Orthoxia Flutter app
    return jsonResponse({
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
  },
};
