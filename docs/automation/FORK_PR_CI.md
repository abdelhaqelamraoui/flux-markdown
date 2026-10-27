# Fork PR CI permissions

Verified on 2026-10-27. Public-repository contributor approval policy is
`first_time_contributors_new_to_github` (previously `first_time_contributors`).
Only first-time contributors who are also new to GitHub require approval.
GitHub does not expose a public-repository policy that exempts every contributor.
Repository default workflow permissions remain `read`; approving PR reviews from
Actions remains disabled.

## Execution boundaries

- `ci.yml`: ordinary `pull_request`, `contents: read`, GitHub-hosted runners,
  no repository Secrets, and no persisted checkout credentials. Builds and tests
  run with code signing disabled. Fork code must never run with notification or
  release credentials.
- `classify-issues.yml`: only Issue events; retains the existing Azure classifier.
- `label-merged-pr.yml`: trusted `pull_request_target` workflow after merge,
  limited to issue labels. No checkout, shell execution, or Secrets. PR text is
  data passed to the GitHub API, never executable code.
- `feishu-notify.yml`: privileged notification workflow checks out only the
  default branch; review artifacts are parsed as JSON, never executed.
- `release-build.yml`: manual workflow, separate from PR CI.

The previous mixed Issue/PR labeling workflow is split to make these boundaries
explicit. The old ordinary fork PR event could not reliably obtain issue-write
permission for labeling. This change preserves existing labeling behavior; it
does not redefine the repository's released-fix labeling policy.

## Verification and rollback

Run `node --test scripts/tests/workflow-security.test.cjs scripts/tests/feishu-notify.test.cjs`.
The security tests cover the event/Secret boundary, trusted notification checkout,
and the absence of PR code execution in the privileged label workflow. They are
regression guards, not a complete security audit.

Read the live policy with:

```sh
gh api repos/xykong/flux-markdown/actions/permissions/fork-pr-contributor-approval
```

Restore the previous policy with:

```sh
gh api --method PUT repos/xykong/flux-markdown/actions/permissions/fork-pr-contributor-approval -f approval_policy=first_time_contributors
```

Expired runs are not automatically restarted by changing policy. New eligible
fork PR events can run automatically; newcomers can still require approval.

[GitHub policy API](https://docs.github.com/en/rest/actions/permissions)
