import { encryptSecret, serviceRequest, verifyState } from "../../_lib/security.js";

export async function onRequestGet({ request, env }) {
  const requestUrl = new URL(request.url);
  const origin = env.APP_BASE_URL || requestUrl.origin;
  try {
    if (!env.OAUTH_STATE_SECRET || !env.CALENDAR_TOKEN_KEY) throw new Error("Calendar security is not configured.");
    const state = await verifyState(requestUrl.searchParams.get("state"), env.OAUTH_STATE_SECRET);
    const code = requestUrl.searchParams.get("code");
    if (!code) throw new Error(requestUrl.searchParams.get("error_description") || "Authorization was cancelled.");
    const redirectUri = `${origin}/api/calendar/callback`;
    let tokenUrl, values;
    if (state.provider === "google") {
      tokenUrl = "https://oauth2.googleapis.com/token";
      values = { code, client_id: env.GOOGLE_CALENDAR_CLIENT_ID, client_secret: env.GOOGLE_CALENDAR_CLIENT_SECRET, redirect_uri: redirectUri, grant_type: "authorization_code" };
    } else if (state.provider === "outlook") {
      tokenUrl = `https://login.microsoftonline.com/${env.MICROSOFT_TENANT_ID || "common"}/oauth2/v2.0/token`;
      values = { code, client_id: env.MICROSOFT_CALENDAR_CLIENT_ID, client_secret: env.MICROSOFT_CALENDAR_CLIENT_SECRET, redirect_uri: redirectUri, grant_type: "authorization_code", scope: "offline_access Calendars.ReadWrite" };
    } else throw new Error("Unknown calendar provider.");
    const tokenResponse = await fetch(tokenUrl, { method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams(values) });
    const tokens = await tokenResponse.json();
    if (!tokenResponse.ok || !tokens.access_token) throw new Error("The calendar provider did not return access.");
    const stored = await serviceRequest(env, "calendar_connections?on_conflict=user_id,provider", {
      method: "POST",
      headers: { prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify({
        user_id: state.uid,
        provider: state.provider,
        access_token_encrypted: await encryptSecret(tokens.access_token, env.CALENDAR_TOKEN_KEY),
        refresh_token_encrypted: await encryptSecret(tokens.refresh_token, env.CALENDAR_TOKEN_KEY),
        expires_at: new Date(Date.now() + Number(tokens.expires_in || 3600) * 1000).toISOString(),
        updated_at: new Date().toISOString(),
      }),
    });
    if (!stored.ok) throw new Error("The encrypted calendar connection could not be stored.");
    return Response.redirect(`${origin}/?calendar=connected&provider=${state.provider}`, 302);
  } catch (error) {
    return Response.redirect(`${origin}/?calendar=error&message=${encodeURIComponent(error.message || "Connection failed")}`, 302);
  }
}
