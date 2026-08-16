import { authenticatedUser, json, serviceRequest } from "../../_lib/security.js";

export async function onRequestGet({ request, env }) {
  try {
    const user = await authenticatedUser(request, env);
    const response = await serviceRequest(env, `calendar_connections?user_id=eq.${encodeURIComponent(user.id)}&select=provider,updated_at`);
    if (!response.ok) return json({ error: "Calendar status is unavailable." }, 502);
    return json({ connections: await response.json() });
  } catch (error) {
    if (error instanceof Response) return new Response(error.body, { status: error.status, headers: { "content-type": "application/json" } });
    return json({ error: "Calendar status is unavailable." }, 500);
  }
}
