// Live AI is retired while Pebble is a click-through product guide.
// Do not read request bodies, authenticate against private records or call a provider.
export function onRequest() {
  return Response.json({error: 'Pebble is now a click-through app guide. Open Pebble walkthrough from the app navigation.'},
    {status: 410, headers: {'cache-control': 'no-store'}});
}
export const onRequestPost = onRequest;
