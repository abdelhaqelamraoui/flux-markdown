const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createHmac } = require('node:crypto');
const { buildMessage, sendMessage } = require('../feishu-notify.cjs');
const repository = { full_name: 'xykong/flux-markdown', html_url: 'https://github.com/xykong/flux-markdown' };
const issue = { number: 7, title: 'A title', body: 'Details', html_url: `${repository.html_url}/issues/7` };
const base = { repository, sender: { login: 'reporter' }, action: 'opened', issue };
test('issue details, configured mention, and no accidental mentions from input', () => {
  const p = buildMessage('issues', { ...base, issue: { ...issue, body: '<at user_id="all">everyone</at>' } }, 'ou_example');
  assert.equal(p.msg_type, 'text');
  assert.match(p.content.text, /Issue #7 · 新建/);
  assert.match(p.content.text, /reporter/);
  assert.match(p.content.text, /<at user_id="ou_example">/);
  assert.doesNotMatch(p.content.text, /<at user_id="all">/);
  assert.match(p.content.text, /issues\/7/);
});
test('merge and fork PR notifications', () => {
  const p = buildMessage('pull_request_target', { ...base, action: 'closed', pull_request: { ...issue, merged: true, head: { repo: { fork: true } } } });
  assert.match(p.content.text, /PR #7 · 已合并/);
  assert.doesNotMatch(p.content.text, /<at/);
});
test('PR conversation comments retain comment permalink', () => {
  const p = buildMessage('issue_comment', { ...base, action: 'created', issue: { ...issue, pull_request: {} }, comment: { body: 'reply', html_url: `${issue.html_url}#issuecomment-1` } });
  assert.match(p.content.text, /PR #7 · 新评论/);
  assert.match(p.content.text, /reply/);
  assert.match(p.content.text, /#issuecomment-1/);
});
test('reviews, inline comments and manual smoke notification', () => {
  assert.match(buildMessage('pull_request_review', { ...base, pull_request: issue, review: { state: 'approved', body: 'LGTM' } }).content.text, /approved/);
  assert.match(buildMessage('pull_request_review_comment', { ...base, pull_request: issue, comment: { body: 'fix', path: 'a.swift', html_url: issue.html_url } }).content.text, /a.swift/);
  assert.match(buildMessage('workflow_dispatch', { repository }).content.text, /测试/);
});
test('body is bounded and invalid mention IDs are rejected', () => {
  assert.ok(buildMessage('issues', { ...base, issue: { ...issue, body: '😀'.repeat(40000) } }).content.text.length < 4500);
  assert.throws(() => buildMessage('issues', base, 'all'), /Open ID/);
});
test('signed payload and business status are checked', async () => {
  let sent;
  await sendMessage({ msg_type: 'text', content: { text: 'test' } }, { url: 'https://open.feishu.cn/open-apis/bot/v2/hook/example', secret: 'test-secret', now: () => 123000, fetchImpl: async (_, init) => { sent = JSON.parse(init.body); return { ok: true, json: async () => ({ code: 0 }) }; } });
  assert.equal(sent.timestamp, '123');
  assert.equal(sent.sign, createHmac('sha256', '123\ntest-secret').update('').digest('base64'));
  await assert.rejects(sendMessage({}, { url: 'https://open.feishu.cn/open-apis/bot/v2/hook/example', fetchImpl: async () => ({ ok: true, json: async () => ({ code: 19024 }) }) }), /19024/);
});
test('transient HTTP failures retry; timeout and business errors do not', async () => {
  let calls = 0;
  const opts = { url: 'https://open.feishu.cn/open-apis/bot/v2/hook/example', sleep: async () => {}, fetchImpl: async () => { calls++; return calls < 3 ? { ok: false, status: 503 } : { ok: true, json: async () => ({ StatusCode: 0 }) }; } };
  await sendMessage({}, opts);
  assert.equal(calls, 3);
  calls = 0;
  await assert.rejects(sendMessage({}, { ...opts, fetchImpl: async () => { calls++; throw new Error('secret URL'); } }), /network/);
  assert.equal(calls, 1);
});
