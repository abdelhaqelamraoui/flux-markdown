const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '../..');
const readWorkflow = (name) => fs.readFileSync(path.join(root, '.github/workflows', name), 'utf8');

test('fork PR CI is read-only and does not consume secrets', () => {
  const ci = readWorkflow('ci.yml');
  assert.match(ci, /pull_request:/);
  assert.match(ci, /permissions:\s*\n\s+contents:\s+read/);
  assert.doesNotMatch(ci, /secrets\./);
  assert.doesNotMatch(ci, /pull_request_target:/);
});

test('secret-backed issue classification is isolated from PR workflows', () => {
  const classifier = readWorkflow('classify-issues.yml');
  assert.match(classifier, /issues:/);
  assert.match(classifier, /secrets\.AZURE_OPENAI_API_KEY/);
  assert.doesNotMatch(classifier, /pull_request(?:_target)?:/);
});

test('merged PR labeling uses trusted base workflow without secrets', () => {
  const labeling = readWorkflow('label-merged-pr.yml');
  assert.match(labeling, /pull_request_target:/);
  assert.match(labeling, /issues:\s+write/);
  assert.doesNotMatch(labeling, /secrets\./);
  assert.doesNotMatch(labeling, /actions\/checkout|\n\s+run:/);
});

test('no workflow mixes pull_request with secret references', () => {
  const workflowDir = path.join(root, '.github/workflows');
  for (const name of fs.readdirSync(workflowDir).filter((file) => file.endsWith('.yml') || file.endsWith('.yaml'))) {
    const content = fs.readFileSync(path.join(workflowDir, name), 'utf8');
    assert.equal(/(?:^|\n)\s*pull_request:\s*(?:\n|$)/.test(content) && /secrets\./.test(content), false, `${name} mixes pull_request and secrets`);
  }
});

 test('secret-backed notifications only check out trusted default branch', () => {
  const notify = readWorkflow('feishu-notify.yml');
  assert.match(notify, /ref: \$\{\{ github.event.repository.default_branch \}\}/);
  assert.match(notify, /persist-credentials: false/);
  assert.doesNotMatch(notify, /pull_request.head|head.sha|head.ref/);
});
