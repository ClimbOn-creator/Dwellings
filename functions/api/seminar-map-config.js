export function onRequestGet({ env }) {
  const token = env.MAPBOX_PUBLIC_TOKEN;
  return Response.json(
    { mapboxToken: typeof token === "string" && /^pk\.[\w-]+\.[\w-]+$/.test(token) ? token : null },
    { headers: { "Cache-Control": "no-store" } },
  );
}
