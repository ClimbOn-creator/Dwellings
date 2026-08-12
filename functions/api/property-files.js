async function authenticatedUser(request, env) {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ") || !env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) return null;
  const response = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
    headers: { Authorization: authorization, apikey: env.SUPABASE_PUBLISHABLE_KEY },
  });
  return response.ok ? response.json() : null;
}

async function accessibleDealRoom(request, env, roomId) {
  const authorization = request.headers.get("Authorization");
  const endpoint = new URL(`${env.SUPABASE_URL}/rest/v1/deal_rooms`);
  endpoint.searchParams.set("id", `eq.${roomId}`);
  endpoint.searchParams.set("select", "id,transaction_type");
  const response = await fetch(endpoint, {
    headers: {
      Authorization: authorization,
      apikey: env.SUPABASE_PUBLISHABLE_KEY,
    },
  });
  if (!response.ok) return null;
  const rooms = await response.json();
  return rooms.length === 1 ? rooms[0] : null;
}

const allowedFiles = new Map([
  ["application/pdf", new Set(["pdf"])],
  ["image/jpeg", new Set(["jpg", "jpeg"])],
  ["image/png", new Set(["png"])],
  ["application/msword", new Set(["doc"])],
  ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", new Set(["docx"])],
]);

export async function onRequestPost(context) {
  const user = await authenticatedUser(context.request, context.env);
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  if (!context.env.PROPERTY_FILES) return Response.json({ error: "R2 binding is not configured" }, { status: 503 });

  const form = await context.request.formData();
  const file = form.get("file");
  const analysisId = String(form.get("analysisId") || "").trim();
  if (!(file instanceof File) || file.size === 0) return Response.json({ error: "A file is required" }, { status: 400 });
  if (file.size > 15 * 1024 * 1024) return Response.json({ error: "Maximum file size is 15 MB" }, { status: 413 });
  if (!/^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(analysisId)) {
    return Response.json({ error: "A valid workspace is required" }, { status: 400 });
  }

  const room = await accessibleDealRoom(context.request, context.env, analysisId);
  if (!room) return Response.json({ error: "Workspace not found or access denied" }, { status: 403 });
  if (room.transaction_type === "business") {
    return Response.json({
      error: "Confidential acquisition uploads are disabled until the secure document vault is released",
    }, { status: 403 });
  }

  const extension = file.name.includes(".") ? file.name.split(".").pop().toLowerCase() : "";
  if (!allowedFiles.get(file.type)?.has(extension)) {
    return Response.json({ error: "Only PDF, DOC, DOCX, JPG and PNG files are accepted" }, { status: 415 });
  }

  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const key = `${user.id}/${analysisId}/${crypto.randomUUID()}-${safeName}`;
  await context.env.PROPERTY_FILES.put(key, file.stream(), {
    httpMetadata: { contentType: file.type || "application/octet-stream" },
    customMetadata: { userId: user.id, analysisId, originalName: file.name },
  });
  return Response.json({ key, name: file.name, size: file.size }, { status: 201 });
}
