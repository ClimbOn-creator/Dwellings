const json = (body, status = 200) => Response.json(body, { status, headers: { "cache-control": "no-store" } });

export async function onRequestPost({ request, env }) {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) return json({ error: "Authentication is not configured." }, 503);
  if (!env.RESEND_API_KEY || !env.CONSULTING_EMAIL) return json({ error: "Consulting email is not configured." }, 503);
  const authorization = request.headers.get("authorization") || "";
  if (!authorization.startsWith("Bearer ")) return json({ error: "Sign in is required." }, 401);
  const userResponse = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, { headers: { authorization, apikey: env.SUPABASE_PUBLISHABLE_KEY } });
  if (!userResponse.ok) return json({ error: "Your session could not be verified." }, 401);
  const user = await userResponse.json();
  const body = await request.json().catch(() => null);
  if (!body || !String(body.outcome || "").trim()) return json({ error: "Tell us what outcome you need." }, 400);
  const safe = (value) => String(value || "").replace(/[<>]/g, "").slice(0, 3000);
  const email = safe(user.email);
  const name = safe(user.user_metadata?.full_name || user.user_metadata?.display_name || email.split("@")[0]);
  const payload = {
    from: env.CONSULTING_FROM_EMAIL || "DwellingIQ <onboarding@resend.dev>",
    to: [env.CONSULTING_EMAIL],
    reply_to: email,
    subject: `DwellingIQ consulting request — ${safe(body.format)}`,
    text: [`New personalized consulting request`, ``, `Name: ${name}`, `Email: ${email}`, `Phone: ${safe(body.phone) || "Not provided"}`, `Format: ${safe(body.format)}`, ``, `Desired outcome:`, safe(body.outcome), ``, `Current challenge:`, safe(body.challenge)].join("\n"),
  };
  const sent = await fetch("https://api.resend.com/emails", { method: "POST", headers: { authorization: `Bearer ${env.RESEND_API_KEY}`, "content-type": "application/json" }, body: JSON.stringify(payload) });
  if (!sent.ok) return json({ error: "The request could not be emailed. Please try again." }, 502);
  return json({ ok: true });
}
