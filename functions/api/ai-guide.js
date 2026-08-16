import { authenticatedUser, json } from "../_lib/security.js";

const schema = {
  type: "object",
  additionalProperties: false,
  required: ["message", "blueprint_patch", "calendar_events", "suggested_action"],
  properties: {
    message: { type: "string" },
    blueprint_patch: {
      type: "object",
      additionalProperties: false,
      required: ["type", "geography", "minPrice", "maxPrice", "minReturn", "involvement", "industries", "limits", "stretch"],
      properties: Object.fromEntries(["type", "geography", "minPrice", "maxPrice", "minReturn", "involvement", "industries", "limits", "stretch"].map((key) => [key, { type: "string", description: "An empty string means no proposed change." }])),
    },
    calendar_events: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["title", "date"],
        properties: {
          title: { type: "string" },
          date: { type: "string", description: "ISO 8601 date/time" },
        },
      },
    },
    suggested_action: { type: "string" },
  },
};

export async function onRequestPost({ request, env }) {
  try {
    await authenticatedUser(request, env);
    if (!env.OPENAI_API_KEY) return json({ error: "AI generation is not configured." }, 503);
    const body = await request.json().catch(() => null);
    const messages = Array.isArray(body?.messages) ? body.messages.slice(-20) : [];
    if (!messages.length) return json({ error: "A message is required." }, 400);
    const context = JSON.stringify(body?.workspace || {}).slice(0, 12000);
    const conversation = messages.map((item) => ({
      role: item.role === "assistant" ? "assistant" : "user",
      content: String(item.text || "").slice(0, 4000),
    }));
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        authorization: `Bearer ${env.OPENAI_API_KEY}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: env.OPENAI_MODEL || "gpt-5-mini",
        instructions: `You are DwellingIQ, a specialized business-acquisition copilot. Remember and use the supplied workspace. Help the user complete acquisition fields, assess readiness, prepare diligence, draft useful material, and turn decisions into calendar actions. Ask a focused question when material facts are missing. Never claim certainty, invent financial facts, or perform an external action. Calendar items and blueprint edits are proposals the user must review. Keep the answer concise and specific. Workspace JSON: ${context}`,
        input: conversation,
        max_output_tokens: 1400,
        text: { format: { type: "json_schema", name: "dwellingiq_result", strict: true, schema } },
      }),
    });
    const result = await response.json();
    if (!response.ok) return json({ error: "The AI could not complete that request." }, 502);
    const output = (result.output || []).flatMap((item) => item.content || []).find((item) => item.type === "output_text")?.text;
    if (!output) return json({ error: "The AI returned no usable response." }, 502);
    return json({ ...JSON.parse(output), response_id: result.id });
  } catch (error) {
    if (error instanceof Response) return new Response(error.body, { status: error.status, headers: { "content-type": "application/json", "cache-control": "no-store" } });
    return json({ error: "The AI request could not be completed." }, 500);
  }
}
