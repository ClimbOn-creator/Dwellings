import test from 'node:test';
import assert from 'node:assert/strict';
import {onRequestPost, onRequest} from '../functions/api/nova.js';
test('retired chat endpoint does not read private context or call any provider', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = () => { throw new Error('No external calls allowed'); };
  try {
    const result = onRequestPost({request: {json() {throw Error('Do not read');}}, env: {OPENAI_API_KEY: 'unused'}});
    assert.equal(result.status, 410);
    assert.match((await result.json()).error, /click-through app guide/);
  } finally {globalThis.fetch = original;}
});
test('guide endpoint requires no AI key or migration', async () => {
  assert.equal(onRequest({env: {}}).status, 410);
});
