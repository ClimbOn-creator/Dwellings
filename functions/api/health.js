export async function onRequestGet(context) {
  return Response.json({
    ok: true,
    service: "dwellings-iq",
    r2Configured: Boolean(context.env.PROPERTY_FILES),
    supabaseConfigured: Boolean(context.env.SUPABASE_URL && context.env.SUPABASE_PUBLISHABLE_KEY),
    timestamp: new Date().toISOString(),
  });
}
