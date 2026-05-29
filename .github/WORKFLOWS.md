# GitHub Actions — Conventions & Hardening Checklist

This document records the CI setup for `github-flow-kit` and the best practices
applied. Use it as a baseline to make Actions reliable across all
`thinkyou0714/*` repositories.

## Workflows in this repo

| Workflow | Trigger | Purpose |
|---|---|---|
| `actionlint.yml` | PR / push touching `.github/workflows/**` | Lints the workflows themselves (syntax, expressions, shellcheck). Meta-CI that guarantees the others are valid before they run. |
| `skill-validate.yml` | PR / push touching skills | Validates `SKILL.md` frontmatter, scans for leaked secrets, checks referenced files exist. |
| `auto-release-notes.yml` | `release: published` | Generates user-facing notes from the git log via the Claude API and updates the release body. |
| `skill-release-announce.yml` | `release: published` | Posts a release announcement to Slack (if a webhook secret is configured). |
| `weekly-triage.yml` | Mon 10:00 JST + manual | Scores open issues and publishes a triage report to the job summary. |

## Hardening checklist (apply to every workflow)

1. **Never reference `secrets` in an `if:` condition.** Secrets are not
   available in `if` (job or step level). Expose the secret as a **job-level
   `env:`** var and gate the step on `env.X`.
   See: <https://docs.github.com/actions/security-guides/using-secrets-in-github-actions>

2. **Never interpolate untrusted `${{ ... }}` into a `run:` script.** Commit
   messages, issue/PR bodies, release notes, and titles are attacker-controlled
   and can break the script or inject commands. Pass them through `env:` and
   reference the shell variable, or build payloads in Python with `json.dumps` /
   `os.environ`.
   See: <https://docs.github.com/actions/security-guides/security-hardening-for-github-actions#understanding-the-risk-of-script-injections>

3. **Set least-privilege `permissions:`.** Default to `contents: read` and only
   add the scopes a job actually uses. Don't grant `write` scopes a workflow
   never exercises.

4. **Add `concurrency:`** so re-pushes/re-runs cancel or serialize instead of
   piling up.

5. **Don't rely on runner-preinstalled packages.** PyYAML and friends are not
   guaranteed on `ubuntu-latest`. Use `actions/setup-python` + an explicit
   `pip install`.

6. **Pin actions to a commit SHA.** `renovate.json` extends
   `helpers:pinGitHubActionDigests`, so Renovate pins every `uses:` to a full
   commit digest and keeps it updated — closing the mutable-tag supply-chain gap.

7. **Lint workflows in CI** with `actionlint` (which also runs `shellcheck` on
   `run:` steps — `shellcheck` is preinstalled on `ubuntu-latest`). Pin the
   linter version (`ACTIONLINT_VERSION`) so results are reproducible.

8. **Don't mask failures with `continue-on-error`.** Let genuine errors surface
   (red check / owner notification). Handle *expected* conditions explicitly
   instead — e.g. exit 0 when an optional secret is unset.

## Required / optional secrets

| Secret | Used by | Behavior if missing |
|---|---|---|
| `GITHUB_TOKEN` | auto-release-notes, weekly-triage | Provided automatically by Actions. |
| `ANTHROPIC_API_KEY` | auto-release-notes, weekly-triage | Step skips AI generation gracefully. |
| `SLACK_WEBHOOK_URL` | skill-release-announce | Slack step is skipped. |

## Enforce CI (branch protection)

Green checks only matter if they're required to merge. On `main`, add a
**branch protection rule** (or repository ruleset) that requires these status
checks to pass before merging:

- `validate` (from `skill-validate.yml`)
- `actionlint` (from `actionlint.yml`)

Recommended companion settings: require a PR before merging, require branches to
be up to date, and dismiss stale approvals on new commits. Configure at
`Settings → Branches → Add branch protection rule` (or `Settings → Rules`).

> Note: if Actions ever fail to *start* (jobs go red in ~1s as a
> "startup failure" before any step runs), the cause is repository-level, not
> the YAML — check `Settings → Actions → General` (Actions enabled + allowed
> actions) and the account's Actions minutes/spending limit.

## Porting to other `thinkyou0714/*` repos

Copy `actionlint.yml` first — it catches the mistakes above on every PR. Then
adapt the relevant workflows, and run through the checklist for each. Validate
locally before pushing:

```bash
# Pin the version to match actionlint.yml (ACTIONLINT_VERSION).
bash <(curl -sSf https://raw.githubusercontent.com/rhysd/actionlint/v1.7.12/scripts/download-actionlint.bash) 1.7.12
./actionlint -color
```
