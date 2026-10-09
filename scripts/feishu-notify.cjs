const { createHmac } = require('node:crypto');

const clean = (value, limit = 1200) => String(value || '').replace(/</g, '＜').replace(/>/g, '＞').slice(0, limit);
function buildMessage(event, payload, mention = '') {
  if (mention && !/^ou_[a-zA-Z0-9_-]+$/.test(mention)) throw new Error('Invalid mention Open ID');
  const repo = payload.repository;
  if (!repo?.full_name) throw new Error('Missing repository');
  const item = payload.pull_request || payload.issue;
  const isPR = !!payload.pull_request || !!payload.issue?.pull_request;
  const actions = { opened: '新建', edited: '已修改', closed: '已关闭', reopened: '重新打开', deleted: '已删除', synchronize: '提交已更新', ready_for_review: '准备审核', converted_to_draft: '转为草稿', review_requested: '请求审核', review_request_removed: '取消审核请求', locked: '已锁定', unlocked: '已解锁' };
  let action = actions[payload.action] || clean(payload.action, 80);
  let detail = item?.body;
  let link = item?.html_url || repo.html_url;
  if (payload.pull_request?.merged && payload.action === 'closed') action = '已合并';
  if (payload.comment) {
    action = event === 'pull_request_review_comment' ? '代码行评论' : '新评论';
    if (payload.action !== 'created') action += `（${actions[payload.action] || clean(payload.action, 80)}）`;
    detail = [payload.comment.path, payload.comment.body].filter(Boolean).join('\n');
    link = payload.comment.html_url || link;
  }
  if (payload.review) {
    action = `审核 ${clean(payload.review.state, 80)}`;
    detail = payload.review.body;
    link = payload.review.html_url || link;
  }
  const lines = [
    mention ? `<at user_id="${mention}">提醒</at>` : '',
    `GitHub · ${clean(repo.full_name, 200)}`,
    event === 'workflow_dispatch' ? '通知连接测试' : `${isPR ? 'PR' : 'Issue'} #${item?.number} · ${action}`,
    item ? clean(item.title, 300) : '',
    `操作者：${clean(payload.sender?.login || 'GitHub Actions', 100)}`,
    clean(detail), clean(link, 500),
  ];
  return { msg_type: 'text', content: { text: lines.filter(Boolean).join('\n') } };
}

async function sendMessage(message, { url, secret = '', fetchImpl = fetch, now = Date.now, sleep = ms => new Promise(resolve => setTimeout(resolve, ms)) }) {
  if (!/^https:\/\/open\.feishu\.cn\/open-apis\/bot\/v2\/hook\/[a-zA-Z0-9-]+$/.test(url || '')) throw new Error('Missing or invalid FEISHU_WEBHOOK_URL');
  for (let attempt = 0; attempt < 3; attempt++) {
    const body = { ...message };
    if (secret) {
      body.timestamp = String(Math.floor(now() / 1000));
      body.sign = createHmac('sha256', `${body.timestamp}\n${secret}`).update('').digest('base64');
    }
    let response;
    try {
      response = await fetchImpl(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body), signal: AbortSignal.timeout(15000) });
    } catch {
      throw new Error('Feishu network request failed; delivery unknown (not automatically resent)');
    }
    if (!response.ok) {
      if ((response.status === 429 || response.status >= 500) && attempt < 2) { await sleep(1000 * 2 ** attempt); continue; }
      throw new Error(`Feishu HTTP ${response.status}`);
    }
    let result;
    try { result = await response.json(); } catch { throw new Error('Invalid Feishu response (not automatically resent)'); }
    const code = result.code ?? result.StatusCode;
    if (code !== 0) throw new Error(`Feishu error code ${Number.isInteger(code) ? code : 'unknown'}`);
    return { accepted: true, mentionConfigured: /<at user_id=/.test(message.content?.text || '') };
  }
}
module.exports = { buildMessage, sendMessage };
