const MAX_BYTES = 15 * 1024 * 1024;
const allowedFiles = new Map([
  ["application/pdf", { extensions: new Set(["pdf"]), magic: [[0x25, 0x50, 0x44, 0x46]] }],
  ["image/jpeg", { extensions: new Set(["jpg", "jpeg"]), magic: [[0xff, 0xd8, 0xff]] }],
  ["image/png", { extensions: new Set(["png"]), magic: [[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]] }],
]);

function apiHeaders(request, env) {
  return {
    Authorization: request.headers.get("Authorization") || "",
    apikey: env.SUPABASE_PUBLISHABLE_KEY || "",
    "Content-Type": "application/json",
  };
}

async function authenticatedUser(request, env) {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ") || !env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) return null;
  const response = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
    headers: { Authorization: authorization, apikey: env.SUPABASE_PUBLISHABLE_KEY },
  });
  return response.ok ? response.json() : null;
}

async function restSelect(request, env, table, params) {
  const endpoint = new URL(`${env.SUPABASE_URL}/rest/v1/${table}`);
  for (const [key, value] of Object.entries(params)) endpoint.searchParams.set(key, value);
  const response = await fetch(endpoint, { headers: apiHeaders(request, env) });
  if (!response.ok) return [];
  return response.json();
}

async function accessibleDealRoom(request, env, roomId) {
  const rooms = await restSelect(request, env, "deal_rooms", { id: `eq.${roomId}`, select: "id,transaction_type" });
  return rooms.length === 1 ? rooms[0] : null;
}

async function accessibleDocument(request, env, documentId) {
  const rows = await restSelect(request, env, "deal_room_documents", {
    id: `eq.${documentId}`,
    deleted_at: "is.null",
    select: "id,deal_room_id,uploaded_by,object_key,file_name,file_size,content_type,security_status",
  });
  return rows.length === 1 ? rows[0] : null;
}

async function audit(request, env, userId, document, eventType) {
  try {
    await fetch(`${env.SUPABASE_URL}/rest/v1/deal_room_document_events`, {
      method: "POST",
      headers: { ...apiHeaders(request, env), Prefer: "return=minimal" },
      body: JSON.stringify({
        deal_room_id: document.deal_room_id,
        document_id: document.id,
        actor_user_id: userId,
        event_type: eventType,
        file_name: document.file_name,
      }),
    });
  } catch (_) {
    // File access should not fail solely because audit telemetry is unavailable.
  }
}

function matchesMagic(bytes, signatures) {
  return signatures.some((signature) => signature.every((value, index) => bytes[index] === value));
}

function safeDownloadName(value) {
  return value.replace(/[\r\n"\\]/g, "_").slice(0, 180);
}

export async function onRequestPost(context) {
  const user = await authenticatedUser(context.request, context.env);
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  if (!context.env.PROPERTY_FILES) return Response.json({ error: "Private file storage is unavailable" }, { status: 503 });

  const form = await context.request.formData();
  const file = form.get("file");
  const roomId = String(form.get("analysisId") || "").trim();
  if (!(file instanceof File) || file.size === 0) return Response.json({ error: "A file is required" }, { status: 400 });
  if (file.size > MAX_BYTES) return Response.json({ error: "Maximum file size is 15 MB" }, { status: 413 });
  if (!/^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(roomId)) return Response.json({ error: "A valid workspace is required" }, { status: 400 });
  if (!(await accessibleDealRoom(context.request, context.env, roomId))) return Response.json({ error: "Workspace not found or access denied" }, { status: 403 });

  const extension = file.name.includes(".") ? file.name.split(".").pop().toLowerCase() : "";
  const rule = allowedFiles.get(file.type);
  if (!rule?.extensions.has(extension)) {
    return Response.json({ error: "Only PDF, JPG and PNG files are accepted by the secure vault" }, { status: 415 });
  }
  const bytes = new Uint8Array(await file.arrayBuffer());
  if (!matchesMagic(bytes, rule.magic)) return Response.json({ error: "File contents do not match the declared file type" }, { status: 415 });

  const digest = await crypto.subtle.digest("SHA-256", bytes);
  const sha256 = [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_").slice(0, 180);
  const key = `vault/${roomId}/${crypto.randomUUID()}-${safeName}`;
  await context.env.PROPERTY_FILES.put(key, bytes, {
    httpMetadata: { contentType: file.type },
    customMetadata: { userId: user.id, roomId, originalName: file.name, sha256 },
  });
  const metadataResponse = await fetch(`${context.env.SUPABASE_URL}/rest/v1/deal_room_documents`, {
    method: "POST",
    headers: { ...apiHeaders(context.request, context.env), Prefer: "return=representation" },
    body: JSON.stringify({
      deal_room_id: roomId,
      uploaded_by: user.id,
      object_key: key,
      file_name: file.name,
      file_size: file.size,
      content_type: file.type,
      sha256,
      security_status: "validated",
    }),
  });
  if (!metadataResponse.ok) {
    await context.env.PROPERTY_FILES.delete(key);
    return Response.json({ error: "Could not register the private document" }, { status: 500 });
  }
  const [document] = await metadataResponse.json();
  await audit(context.request, context.env, user.id, document, "uploaded");
  return Response.json({ id: document.id, name: file.name, size: file.size, sha256, securityStatus: "validated" }, { status: 201 });
}

export async function onRequestGet(context) {
  const user = await authenticatedUser(context.request, context.env);
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  const documentId = new URL(context.request.url).searchParams.get("documentId") || "";
  const document = await accessibleDocument(context.request, context.env, documentId);
  if (!document || document.security_status !== "validated") {
    return Response.json({ error: "Document not found or access denied" }, { status: 403 });
  }
  const object = await context.env.PROPERTY_FILES.get(document.object_key);
  if (!object) return Response.json({ error: "Stored object was not found" }, { status: 404 });
  await audit(context.request, context.env, user.id, document, "downloaded");
  return new Response(object.body, {
    headers: {
      "Content-Type": document.content_type,
      "Content-Disposition": `attachment; filename="${safeDownloadName(document.file_name)}"`,
      "Cache-Control": "private, no-store, max-age=0",
      "X-Content-Type-Options": "nosniff",
      "Content-Security-Policy": "default-src 'none'; sandbox",
    },
  });
}

export async function onRequestDelete(context) {
  const user = await authenticatedUser(context.request, context.env);
  if (!user) return Response.json({ error: "Authentication required" }, { status: 401 });
  const documentId = new URL(context.request.url).searchParams.get("documentId") || "";
  const document = await accessibleDocument(context.request, context.env, documentId);
  if (!document) return Response.json({ error: "Document not found or access denied" }, { status: 403 });

  await audit(context.request, context.env, user.id, document, "deleted");
  const response = await fetch(`${context.env.SUPABASE_URL}/rest/v1/deal_room_documents?id=eq.${encodeURIComponent(documentId)}`, {
    method: "DELETE",
    headers: { ...apiHeaders(context.request, context.env), Prefer: "return=minimal" },
  });
  if (!response.ok) return Response.json({ error: "You cannot delete this document" }, { status: 403 });
  await context.env.PROPERTY_FILES.delete(document.object_key);
  return Response.json({ deleted: true });
}
