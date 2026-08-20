const json = (body, status = 200) => Response.json(body, { status, headers: { "cache-control": "no-store" } });

export async function onRequestPost({ request, env }) {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY || !env.SUPABASE_SERVICE_ROLE_KEY) {
    return json({ error: "Notification delivery is not configured." }, 503);
  }
  const authorization = request.headers.get("authorization") || "";
  if (!authorization.startsWith("Bearer ")) return json({ error: "Sign in is required." }, 401);
  const verified = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
    headers: { authorization, apikey: env.SUPABASE_PUBLISHABLE_KEY },
  });
  if (!verified.ok) return json({ error: "Your session could not be verified." }, 401);
  if (!env.RESEND_API_KEY) return json({ ok: true, sent: 0, skipped: "Email provider is not configured." });

  const adminHeaders = {
    apikey: env.SUPABASE_SERVICE_ROLE_KEY,
    authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    "content-type": "application/json",
  };
  const pendingResponse = await fetch(
    `${env.SUPABASE_URL}/rest/v1/affinity_notifications?email_status=eq.pending&select=id,user_id,title,message,action_module&order=created_at.asc&limit=10`,
    { headers: adminHeaders },
  );
  if (!pendingResponse.ok) return json({ error: "Could not load the notification queue." }, 502);
  const pending = await pendingResponse.json();
  let sent = 0;
  for (const item of pending) {
    let status = "failed";
    try {
      const userResponse = await fetch(`${env.SUPABASE_URL}/auth/v1/admin/users/${item.user_id}`, { headers: adminHeaders });
      if (!userResponse.ok) throw new Error("user lookup failed");
      const user = await userResponse.json();
      if (!user.email) throw new Error("user has no email");
      const link = `${env.APP_BASE_URL || new URL(request.url).origin}/?module=${encodeURIComponent(item.action_module || "member-studio")}`;
      const emailResponse = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { authorization: `Bearer ${env.RESEND_API_KEY}`, "content-type": "application/json" },
        body: JSON.stringify({
          from: env.AFFINITY_FROM_EMAIL || env.CONSULTING_FROM_EMAIL || "Affinity <onboarding@resend.dev>",
          to: [user.email],
          subject: item.title,
          text: `${item.message}\n\nOpen Affinity: ${link}\n\nThis is a private transactional update about your Affinity account.`,
        }),
      });
      if (!emailResponse.ok) throw new Error("email provider rejected request");
      status = "sent";
      sent += 1;
    } catch (_) {
      status = "failed";
    }
    await fetch(`${env.SUPABASE_URL}/rest/v1/affinity_notifications?id=eq.${item.id}`, {
      method: "PATCH",
      headers: adminHeaders,
      body: JSON.stringify({ email_status: status, email_attempted_at: new Date().toISOString() }),
    });
  }
  return json({ ok: true, sent, processed: pending.length });
}
