# OpenSSF-aligned checks — rationale + sources

Read this when a user asks *why* a check matters or how to remediate it.

## Token-Permissions (default_workflow_permissions)
The built-in `GITHUB_TOKEN` should default to **read**. A compromised step with write can push code.
Highest assurance: top-level `permissions: { contents: read }` plus run-level writes only where needed.
- Secure: `read`. WARN if `write`.
- Fix: repo Settings → Actions → General → Workflow permissions → "Read repository contents…", and
  declare explicit `permissions:` blocks per workflow.

## Allowed actions policy (allowed_actions)
`all` lets any third-party action run (supply-chain surface). Stricter: `selected` with verified
creators + an explicit allowlist, or `local_only`.
- INFO (opinionated): `all`. Tighten via Settings → Actions → General, staging carefully.

## Branch-Protection
A protected default branch requiring review (ideally from someone other than the actor) prevents
direct/bot pushes and self-approval merges. Compensating control for any token that can open PRs.
- INFO: none. Enable via `gh api -X PUT repos/<o>/<r>/branches/<b>/protection ...` or the UI.

## Secret scanning + push protection
Detects committed secrets and blocks pushes that contain them. Free on **public** repos (and via
GitHub Advanced Security on private). 
- WARN if a **public** repo is not `enabled`. Private repos without GHAS report `n/a` (expected).

## Dependabot alerts
Surfaces known-vulnerable dependencies. Free on all repos, no downside.
- WARN if `off`. Safe to enable: `gh api -X PUT repos/<o>/<r>/vulnerability-alerts` (DELETE to undo).
  This is the only mutation this skill will perform, and only with `--enable-dependabot`.

## Dangerous-Workflow (heuristic, not via REST)
`pull_request_target` / `workflow_run` run with write access + secrets of the target repo. If they
check out the PR head and execute it, untrusted code runs privileged (RCE / secret exfil). Also
avoid interpolating `${{ github.event.* }}` directly into `run:` (script injection).
- Review such workflows manually; this skill flags their presence only if workflow files are local.

## Pinned-Dependencies (heuristic)
`uses: owner/action@v4` (tag/branch) can be rewritten by the action author. Pin by full 40-char
commit SHA: `uses: owner/action@<sha>`. Keep updated via Dependabot `package-ecosystem: github-actions`
or tools like `ratchet` / `pin-github-action`.

## Sources
- OpenSSF Scorecard — checks documentation:
  https://github.com/ossf/scorecard/blob/main/docs/checks.md
- OpenSSF Scorecard project: https://openssf.org/projects/scorecard/
- OpenSSF — Workflows Should Not Be Allowed To Approve Pull Requests:
  https://best.openssf.org/SCM-BestPractices/github/actions/actions_can_approve_pull_requests.html
- GitHub Docs — About Dependabot alerts:
  https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts
- GitHub Docs — Managing GitHub Actions settings for a repository:
  https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
