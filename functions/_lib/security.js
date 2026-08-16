const encoder = new TextEncoder();
const decoder = new TextDecoder();

export const json = (body, status = 200) =>
  Response.json(body, {
    status,
    headers: { "cache-control": "no-store" },
  });

export async function authenticatedUser(request, env) {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) {
    throw new Response(JSON.stringify({ error: "Authentication is not configured." }), { status: 503 });
  }
  const authorization = request.headers.get("authorization") || "";
  if (!authorization.startsWith("Bearer ")) {
    throw new Response(JSON.stringify({ error: "Sign in is required." }), { status: 401 });
  }
  const response = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
    headers: { authorization, apikey: env.SUPABASE_PUBLISHABLE_KEY },
  });
  if (!response.ok) {
    throw new Response(JSON.stringify({ error: "Your session could not be verified." }), { status: 401 });
  }
  return response.json();
}

const b64url = (bytes) => {
  let raw = "";
  for (const byte of bytes) raw += String.fromCharCode(byte);
  return btoa(raw).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
};

const fromB64url = (value) => {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const raw = atob(normalized + "=".repeat((4 - (normalized.length % 4)) % 4));
  return Uint8Array.from(raw, (character) => character.charCodeAt(0));
};

export async function signState(payload, secret) {
  const encoded = b64url(encoder.encode(JSON.stringify(payload)));
  const key = await crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(encoded));
  return `${encoded}.${b64url(new Uint8Array(signature))}`;
}

export async function verifyState(value, secret) {
  const [encoded, signature] = String(value || "").split(".");
  if (!encoded || !signature) throw new Error("Invalid authorization state.");
  const key = await crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["verify"]);
  const valid = await crypto.subtle.verify("HMAC", key, fromB64url(signature), encoder.encode(encoded));
  if (!valid) throw new Error("Invalid authorization state.");
  const payload = JSON.parse(decoder.decode(fromB64url(encoded)));
  if (!payload.exp || payload.exp < Math.floor(Date.now() / 1000)) throw new Error("Authorization state expired.");
  return payload;
}

async function encryptionKey(secret) {
  const bytes = fromB64url(secret);
  if (bytes.byteLength !== 32) throw new Error("CALENDAR_TOKEN_KEY must be a base64url-encoded 32-byte key.");
  return crypto.subtle.importKey("raw", bytes, "AES-GCM", false, ["encrypt", "decrypt"]);
}

export async function encryptSecret(value, secret) {
  if (!value) return null;
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, await encryptionKey(secret), encoder.encode(value));
  return `${b64url(iv)}.${b64url(new Uint8Array(encrypted))}`;
}

export async function decryptSecret(value, secret) {
  if (!value) return null;
  const [iv, encrypted] = value.split(".");
  const clear = await crypto.subtle.decrypt({ name: "AES-GCM", iv: fromB64url(iv) }, await encryptionKey(secret), fromB64url(encrypted));
  return decoder.decode(clear);
}

export async function serviceRequest(env, path, options = {}) {
  if (!env.SUPABASE_SERVICE_ROLE_KEY) throw new Error("Supabase service access is not configured.");
  const serverKey = env.SUPABASE_SERVICE_ROLE_KEY;
  return fetch(`${env.SUPABASE_URL}/rest/v1/${path}`, {
    ...options,
    headers: {
      apikey: serverKey,
      ...(serverKey.startsWith("sb_secret_") ? {} : { authorization: `Bearer ${serverKey}` }),
      "content-type": "application/json",
      ...(options.headers || {}),
    },
  });
}
