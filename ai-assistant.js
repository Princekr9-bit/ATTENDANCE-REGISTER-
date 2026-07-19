// This runs on Vercel's server. Uses Google Gemini API (FREE tier, no credit card
// needed — just a Google account). The app sends the user's Hinglish command plus
// a compact list of workers/sites (with their exact IDs) so Gemini can pick the
// right one instead of guessing from free text. Gemini replies with either
// function calls (actions to execute) or plain text (a question/error to show the user).

const TOOLS = [
  {
    name: "mark_attendance",
    description: "Mark a worker's attendance for a date. For Labourer/Mason (majdoor/mistri), siteId is required when status is P or H. For Driver/Supervisor, siteId is not needed.",
    parameters: {
      type: "object",
      properties: {
        workerId: { type: "string", description: "Exact id of the worker from the provided list" },
        status: { type: "string", enum: ["P", "H", "A"], description: "P=Full day present, H=Half day, A=Absent" },
        siteId: { type: "string", description: "Exact site id from the provided list (required for majdoor/mistri when status is P or H)" },
        date: { type: "string", description: "Date in YYYY-MM-DD format. Defaults to today if omitted." }
      },
      required: ["workerId", "status"]
    }
  },
  {
    name: "record_payment",
    description: "Record a wage/salary payment given to a worker (labourer, mason, driver, or supervisor) for a specific day.",
    parameters: {
      type: "object",
      properties: {
        workerId: { type: "string", description: "Exact id of the worker from the provided list" },
        amount: { type: "number" },
        date: { type: "string", description: "YYYY-MM-DD, defaults to today" },
        note: { type: "string" }
      },
      required: ["workerId", "amount"]
    }
  },
  {
    name: "record_advance",
    description: "Record an advance payment given to a worker.",
    parameters: {
      type: "object",
      properties: {
        workerId: { type: "string" },
        amount: { type: "number" },
        date: { type: "string" },
        note: { type: "string" }
      },
      required: ["workerId", "amount"]
    }
  },
  {
    name: "add_todo",
    description: "Add a to-do task for a specific date.",
    parameters: {
      type: "object",
      properties: {
        task: { type: "string" },
        date: { type: "string", description: "YYYY-MM-DD, defaults to today" }
      },
      required: ["task"]
    }
  },
  {
    name: "add_driver_note",
    description: "Save a note about what a driver did/moved on a given date.",
    parameters: {
      type: "object",
      properties: {
        driverId: { type: "string" },
        note: { type: "string" },
        date: { type: "string" }
      },
      required: ["driverId", "note"]
    }
  }
];

module.exports = async (req, res) => {
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method not allowed' }); return; }
  try {
    const { message, context, apiKey } = req.body || {};
    if (!message || typeof message !== 'string') { res.status(400).json({ error: 'message is required' }); return; }
    const useKey = apiKey || process.env.GEMINI_API_KEY;
    if (!useKey) { res.status(400).json({ error: 'No API key provided. Please add your free Gemini API key in Company Info settings.' }); return; }

    const systemPrompt = `Tum "Nirman Manager" construction app ke andar ek AI assistant ho. User Hinglish mein commands denge jaise attendance maarna, payment dena, advance dena, todo add karna, ya driver note likhna.

Aaj ki date: ${context && context.today || ''}

Available workers (name | id | kind):
${(context && context.workers || []).map(w => `${w.name} | ${w.id} | ${w.kind}`).join('\n')}

Available sites (name | id):
${(context && context.sites || []).map(s => `${s.name} | ${s.id}`).join('\n')}

Rules:
- Sirf upar diye gaye exact worker/site ids use karo functions mein, kabhi khud se id mat banao.
- Agar user ka bataya naam kisi worker se clearly match nahi karta, ya 2+ workers match karte hain (ambiguous), to koi function mat bulao — iske bajaye plain text mein user se pooch lo ki kaunsa worker (options list karo).
- Agar Labourer/Mason ka Present/Half-day attendance maarna ho aur user ne site nahi bataya, to site ke baare mein pooch lo, khud se mat chuno.
- Ek message mein multiple actions ho sakte hain (jaise 2 logo ka attendance ek saath) — utne functions call karo.
- Jab sab kuch clear ho, seedha function(s) call karo, extra confirmation mat maango.
- Har function call ke baad, ek chhota sa Hinglish confirmation reply bhi do batate hue kya kiya.
- Agar kuch samajh na aaye ya galat lage, plain text mein clearly bata do (function mat bulao).`;

    const model = 'gemini-2.5-flash';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${useKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: message }] }],
        systemInstruction: { parts: [{ text: systemPrompt }] },
        tools: [{ functionDeclarations: TOOLS }]
      })
    });

    const data = await response.json();
    if (!response.ok) {
      res.status(500).json({ error: (data && data.error && data.error.message) || 'AI request failed' });
      return;
    }

    const actions = [];
    let replyText = '';
    const parts = (data.candidates && data.candidates[0] && data.candidates[0].content && data.candidates[0].content.parts) || [];
    parts.forEach(part => {
      if (part.functionCall) {
        actions.push({ name: part.functionCall.name, input: part.functionCall.args || {} });
      } else if (part.text) {
        replyText += part.text;
      }
    });

    res.status(200).json({ reply: replyText, actions });
  } catch (e) {
    res.status(500).json({ error: e.message || 'Unknown server error' });
  }
};
