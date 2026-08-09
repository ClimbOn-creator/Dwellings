async function authenticatedUser(request, env) {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ") || !env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) return null;
  const response = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
    headers: { Authorization: authorization, apikey: env.SUPABASE_PUBLISHABLE_KEY },
  });
  return response.ok ? response.json() : null;
}

export async function onRequestPost(context) {
  const user = await authenticatedUser(context.request, context.env);
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  if (!context.env.PROPERTY_FILES) return Response.json({ error: "R2 binding is not configured" }, { status: 503 });

  const form = await context.request.formData();
  const file = form.get("file");
  const analysisId = String(form.get("analysisId") || "unassigned").replace(/[^a-zA-Z0-9_-]/g, "");
  if (!(file instanceof File) || file.size === 0) return Response.json({ error: "A file is required" }, { status: 400 });
  if (file.size > 15 * 1024 * 1024) return Response.json({ error: "Maximum file size is 15 MB" }, { status: 413 });

  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const key = `${user.id}/${analysisId}/${crypto.randomUUID()}-${safeName}`;
  await context.env.PROPERTY_FILES.put(key, file.stream(), {
    httpMetadata: { contentType: file.type || "application/octet-stream" },
    customMetadata: { userId: user.id, analysisId, originalName: file.name },
  });
  return Response.json({ key, name: file.name, size: file.size }, { status: 201 });
}
