import { authenticatedUser, json, signState } from "../../_lib/security.js";

export async function onRequestPost({ request, env }) {
  try {
    const user = await authenticatedUser(request, env);
    if (!env.OAUTH_STATE_SECRET) return json({ error: "Calendar authorization is not configured." }, 503);
    const body = await request.json().catch(() => ({}));
    const provider = body.provider;
    const origin = env.APP_BASE_URL || new URL(request.url).origin;
    const redirectUri = `${origin}/api/calendar/callback`;
    const state = await signState({ uid: user.id, provider, exp: Math.floor(Date.now() / 1000) + 600 }, env.OAUTH_STATE_SECRET);
    let url;
    if (provider === "google" && env.GOOGLE_CALENDAR_CLIENT_ID) {
      const params = new URLSearchParams({ client_id: env.GOOGLE_CALENDAR_CLIENT_ID, redirect_uri: redirectUri, response_type: "code", scope: "https://www.googleapis.com/auth/calendar", access_type: "offline", prompt: "consent", state });
      url = `https://accounts.google.com/o/oauth2/v2/auth?${params}`;
    } else if (provider === "outlook" && env.MICROSOFT_CALENDAR_CLIENT_ID) {
      const tenant = env.MICROSOFT_TENANT_ID || "common";
      const params = new URLSearchParams({ client_id: env.MICROSOFT_CALENDAR_CLIENT_ID, redirect_uri: redirectUri, response_type: "code", scope: "offline_access Calendars.ReadWrite", response_mode: "query", state });
      url = `https://login.microsoftonline.com/${tenant}/oauth2/v2.0/authorize?${params}`;
    } else return json({ error: "That calendar provider is not configured." }, 503);
    return json({ authorization_url: url });
  } catch (error) {
    if (error instanceof Response) return new Response(error.body, { status: error.status, headers: { "content-type": "application/json" } });
    return json({ error: "Calendar connection could not start." }, 500);
  }
}
