import { authenticatedUser, json } from "../_lib/security.js";

const schema = {
  type: "object",
  additionalProperties: false,
  required: ["subject", "preview", "body"],
  properties: {
    subject: { type: "string" },
    preview: { type: "string" },
    body: { type: "string" },
  },
};

export async function onRequestPost({ request, env }) {
  try {
    const user = await authenticatedUser(request, env);
    if (!env.OPENAI_API_KEY) return json({ error: "AI generation is not configured." }, 503);
    const body = await request.json().catch(() => null);
    if (!["email", "newsletter"].includes(body?.type)) return json({ error: "Choose an email or newsletter draft." }, 400);
    const facts = JSON.stringify(body.fields || {}).slice(0, 10000);
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: { authorization: `Bearer ${env.OPENAI_API_KEY}`, "content-type": "application/json" },
      body: JSON.stringify({
        model: env.OPENAI_MODEL || "gpt-5-mini",
        instructions: "You write polished, useful member communications for DwellingIQ professionals serving property and business-acquisition clients. Use only supplied facts. Do not invent market statistics, credentials, outcomes, or regulatory claims. Avoid hype. Return a complete draft for human review; never claim it was sent.",
        input: `Create a ${body.type} for the authenticated DwellingIQ member ${user.email || ""}. Supplied fields: ${facts}`,
        max_output_tokens: 1800,
        text: { format: { type: "json_schema", name: "member_content", strict: true, schema } },
      }),
    });
    const result = await response.json();
    if (!response.ok) return json({ error: "The AI could not create this draft." }, 502);
    const output = (result.output || []).flatMap((item) => item.content || []).find((item) => item.type === "output_text")?.text;
    if (!output) return json({ error: "The AI returned no usable draft." }, 502);
    return json(JSON.parse(output));
  } catch (error) {
    if (error instanceof Response) return new Response(error.body, { status: error.status, headers: { "content-type": "application/json" } });
    return json({ error: "The draft could not be generated." }, 500);
  }
}
