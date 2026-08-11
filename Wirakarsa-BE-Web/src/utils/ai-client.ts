import dotenv from "dotenv";
dotenv.config();

export interface AIMessage {
  role: "system" | "user" | "assistant";
  content: string | any[];
}

export interface CallAIOptions {
  messages: AIMessage[];
  timeoutMs?: number;
  temperature?: number;
  topP?: number;
}

// Full OpenRouter model chain as fallback
const OPENROUTER_FALLBACK_MODELS = [
  "nvidia/nemotron-3-nano-30b-a3b:free",
  "nvidia/nemotron-nano-9b-v2:free",
  "google/gemma-4-31b-it:free",
  "meta-llama/llama-3.1-8b-instruct:free",
  "meta-llama/llama-3.3-70b-instruct:free",
  "deepseek/deepseek-r1-distill-llama-70b:free",
];

/**
 * Helper to convert openAI-style messages into Gemini Native API contents/systemInstruction format.
 */
function convertToGeminiNative(messages: AIMessage[]) {
  let systemInstructionText = "";
  const contents: any[] = [];

  for (const m of messages) {
    if (m.role === "system") {
      const text = typeof m.content === "string" ? m.content : JSON.stringify(m.content);
      systemInstructionText += (systemInstructionText ? "\n\n" : "") + text;
    } else {
      const role = m.role === "assistant" ? "model" : "user";
      if (typeof m.content === "string") {
        contents.push({
          role,
          parts: [{ text: m.content }],
        });
      } else if (Array.isArray(m.content)) {
        const parts: any[] = [];
        for (const item of m.content) {
          if (item.type === "text") {
            parts.push({ text: item.text });
          } else if (item.type === "image_url" && item.image_url?.url) {
            const dataUrl = item.image_url.url;
            const match = dataUrl.match(/^data:(image\/[a-zA-Z+]+);base64,(.+)$/);
            if (match) {
              parts.push({
                inline_data: {
                  mime_type: match[1],
                  data: match[2],
                },
              });
            }
          }
        }
        if (parts.length > 0) {
          contents.push({ role, parts });
        }
      }
    }
  }

  const payload: Record<string, any> = { contents };
  if (systemInstructionText) {
    payload.system_instruction = {
      parts: [{ text: systemInstructionText }],
    };
  }

  return payload;
}

/**
 * Calls AI with automatic failover:
 * 1. Google Gemini Native API (if GEMINI_API_KEY is set) — fast, reliable, native
 * 2. OpenRouter model chain (free tier fallback)
 */
export async function callAI(options: CallAIOptions): Promise<string | null> {
  const { messages, timeoutMs = 30000, temperature, topP } = options;

  // ─── 1. Try Google Gemini Native API ─────────────────────────────────────
  const geminiKey = process.env.GEMINI_API_KEY;
  let geminiModel = process.env.GEMINI_MODEL || "gemini-2.0-flash";
  // Clean model name if passed with prefix
  geminiModel = geminiModel.replace(/^models\//, "");

  if (geminiKey) {
    try {
      const payload = convertToGeminiNative(messages);
      const generationConfig: Record<string, any> = {};
      if (temperature !== undefined) generationConfig.temperature = temperature;
      if (topP !== undefined) generationConfig.topP = topP;
      if (Object.keys(generationConfig).length > 0) {
        payload.generationConfig = generationConfig;
      }

      const url = `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiKey}`;

      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(timeoutMs),
      });

      if (response.ok) {
        const data = await response.json();
        const candidate = data.candidates?.[0];
        const text = candidate?.content?.parts?.[0]?.text;
        if (text) {
          console.log(`[AI] ✅ Gemini Native success (${geminiModel})`);
          return text;
        }
      } else {
        const errText = await response.text().catch(() => "");
        console.warn(
          `[AI] Gemini Native returned ${response.status}: ${errText.substring(0, 150)}. Falling back to OpenRouter...`
        );
      }
    } catch (error) {
      console.warn(
        `[AI] Gemini Native failed: ${(error as Error).message}. Falling back to OpenRouter...`
      );
    }
  }

  // ─── 2. Fall back to OpenRouter ──────────────────────────────────────────
  const openrouterKey = process.env.OPENROUTER_API_KEY;
  if (!openrouterKey) {
    console.warn("[AI] No GEMINI_API_KEY or OPENROUTER_API_KEY is configured.");
    return null;
  }

  const primaryModel = process.env.OPENROUTER_MODEL || "nvidia/nemotron-3-nano-30b-a3b:free";
  const modelChain = [primaryModel, ...OPENROUTER_FALLBACK_MODELS].filter(
    (m, i, arr) => arr.indexOf(m) === i
  );

  for (const model of modelChain) {
    try {
      const body: Record<string, any> = { model, messages };
      if (temperature !== undefined) body.temperature = temperature;
      if (topP !== undefined) body.top_p = topP;

      const response = await fetch(
        "https://openrouter.ai/api/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${openrouterKey}`,
            "Content-Type": "application/json",
            "HTTP-Referer": "https://wirapath.com",
            "X-Title": "Wirapath",
          },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(timeoutMs),
        }
      );

      if (response.status === 429 || response.status === 404) {
        console.warn(`[AI] OpenRouter model ${model} returned ${response.status}, skipping...`);
        continue;
      }
      if (!response.ok) {
        console.warn(`[AI] OpenRouter model ${model} error ${response.status}: ${response.statusText}`);
        continue;
      }

      const data = await response.json();
      const content = data.choices?.[0]?.message?.content;
      if (content) {
        console.log(`[AI] ✅ OpenRouter success (${model})`);
        return typeof content === "string" ? content : JSON.stringify(content);
      }
    } catch (error) {
      console.warn(
        `[AI] OpenRouter model ${model} failed: ${(error as Error).message}`
      );
    }
  }

  return null;
}
