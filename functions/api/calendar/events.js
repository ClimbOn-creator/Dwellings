import { authenticatedUser, decryptSecret, encryptSecret, json, serviceRequest } from "../../_lib/security.js";

async function connectionFor(env, userId, provider) {
  const response = await serviceRequest(env, `calendar_connections?user_id=eq.${encodeURIComponent(userId)}&provider=eq.${provider}&select=*`);
  if (!response.ok) throw new Error("Calendar connection could not be loaded.");
  return (await response.json())[0];
}

async function saveAccessToken(env, connection, tokens) {
  const response = await serviceRequest(env, `calendar_connections?id=eq.${connection.id}`, {
    method: "PATCH",
    body: JSON.stringify({
      access_token_encrypted: await encryptSecret(tokens.access_token, env.CALENDAR_TOKEN_KEY),
      refresh_token_encrypted: tokens.refresh_token ? await encryptSecret(tokens.refresh_token, env.CALENDAR_TOKEN_KEY) : connection.refresh_token_encrypted,
      expires_at: new Date(Date.now() + Number(tokens.expires_in || 3600) * 1000).toISOString(),
      updated_at: new Date().toISOString(),
    }),
  });
  if (!response.ok) throw new Error("Refreshed calendar access could not be stored.");
  return tokens.access_token;
}

async function accessToken(env, connection) {
  const current = await decryptSecret(connection.access_token_encrypted, env.CALENDAR_TOKEN_KEY);
  if (new Date(connection.expires_at).getTime() > Date.now() + 60000) return current;
  const refresh = await decryptSecret(connection.refresh_token_encrypted, env.CALENDAR_TOKEN_KEY);
  if (!refresh) throw new Error("Reconnect this calendar to continue syncing.");
  let url, values;
  if (connection.provider === "google") {
    url = "https://oauth2.googleapis.com/token";
    values = { client_id: env.GOOGLE_CALENDAR_CLIENT_ID, client_secret: env.GOOGLE_CALENDAR_CLIENT_SECRET, refresh_token: refresh, grant_type: "refresh_token" };
  } else {
    url = `https://login.microsoftonline.com/${env.MICROSOFT_TENANT_ID || "common"}/oauth2/v2.0/token`;
    values = { client_id: env.MICROSOFT_CALENDAR_CLIENT_ID, client_secret: env.MICROSOFT_CALENDAR_CLIENT_SECRET, refresh_token: refresh, grant_type: "refresh_token", scope: "offline_access Calendars.ReadWrite" };
  }
  const response = await fetch(url, { method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams(values) });
  const tokens = await response.json();
  if (!response.ok || !tokens.access_token) throw new Error("Calendar access expired. Reconnect the account.");
  return saveAccessToken(env, connection, tokens);
}

export async function onRequestPost({ request, env }) {
  try {
    const user = await authenticatedUser(request, env);
    if (!env.CALENDAR_TOKEN_KEY) return json({ error: "Calendar sync is not configured." }, 503);
    const body = await request.json().catch(() => null);
    const provider = body?.provider;
    if (!["google", "outlook"].includes(provider)) return json({ error: "Choose Google or Outlook." }, 400);
    const title = String(body?.title || "").trim().slice(0, 200);
    const start = new Date(body?.start);
    if (!title || Number.isNaN(start.getTime())) return json({ error: "A title and valid start time are required." }, 400);
    const end = body?.end ? new Date(body.end) : new Date(start.getTime() + 60 * 60 * 1000);
    const connection = await connectionFor(env, user.id, provider);
    if (!connection) return json({ error: `Connect ${provider === "google" ? "Google Calendar" : "Outlook"} first.` }, 409);
    const token = await accessToken(env, connection);
    const externalId = String(body.external_id || "");
    let url, payload;
    if (provider === "google") {
      url = externalId
        ? `https://www.googleapis.com/calendar/v3/calendars/primary/events/${encodeURIComponent(externalId)}`
        : "https://www.googleapis.com/calendar/v3/calendars/primary/events";
      payload = { summary: title, description: String(body.description || "Created with DwellingIQ").slice(0, 2000), start: { dateTime: start.toISOString() }, end: { dateTime: end.toISOString() } };
    } else {
      url = externalId ? `https://graph.microsoft.com/v1.0/me/events/${encodeURIComponent(externalId)}` : "https://graph.microsoft.com/v1.0/me/events";
      payload = { subject: title, body: { contentType: "text", content: String(body.description || "Created with DwellingIQ").slice(0, 2000) }, start: { dateTime: start.toISOString().replace("Z", ""), timeZone: "UTC" }, end: { dateTime: end.toISOString().replace("Z", ""), timeZone: "UTC" } };
    }
    const response = await fetch(url, { method: externalId ? "PATCH" : "POST", headers: { authorization: `Bearer ${token}`, "content-type": "application/json" }, body: JSON.stringify(payload) });
    const result = response.status === 204 ? {} : await response.json();
    if (!response.ok) return json({ error: "The calendar provider rejected the event. Reconnect and try again." }, 502);
    return json({ ok: true, external_id: result.id || externalId, web_link: result.htmlLink || result.webLink || null });
  } catch (error) {
    if (error instanceof Response) return new Response(error.body, { status: error.status, headers: { "content-type": "application/json" } });
    return json({ error: error.message || "Calendar sync failed." }, 500);
  }
}
