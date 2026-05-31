# Why audit "Allow GitHub Actions to create and approve pull requests"

Read this when a user asks *why* `true` is risky, or pushes back on the recommendation.

## Root cause
- `can_approve_pull_request_reviews = false` is the **secure default** GitHub ships for repos
  created after 2023-02 (personal and org).
- When `true`, a workflow can use the built-in `GITHUB_TOKEN` to **approve a pull request** and
  thereby **bypass required reviews**. A malicious or compromised workflow can approve its own PR
  and merge unreviewed code into the default branch.
- GitHub conflates two things in one toggle: "Actions may **create** PRs" and "Actions may
  **approve** PRs". Enabling it so a bot can merely *open* a PR also grants *approve*. That is why
  the safer pattern for PR creation is a dedicated GitHub App / fine-grained PAT (leaving this
  toggle off), or branch protection that requires a review from someone other than the actor.

## Posture this skill takes
- `false` is correct ("OK(secure-default)"). `true` is an exposure that must be justified per repo
  (pass it via `--allow`). The audit is read-only and never flips the setting; it prints the exact
  `gh api -X PUT ...` command for a human to run.

## How to read the table
- `RISK(unexpected)` = `true` and not in `--allow` → review-bypass exposure, revert recommended.
- `OK(allowlisted)` = `true` but intentionally allowed.
- `OK(secure-default)` = `false`.
- `ERR(skip)` = couldn't read (no admin rights, archived, or transient API error).

## Compensating controls if you must keep `true`
- Branch protection on the default branch requiring at least one review **from someone other than
  the PR author/actor** — a bot self-approval then still cannot merge.
- Prefer a GitHub App installation token (`actions/create-github-app-token`) for any workflow that
  needs to open PRs; it does not require this account-level toggle.

## Sources
- OpenSSF — Workflows Should Not Be Allowed To Approve Pull Requests:
  https://best.openssf.org/SCM-BestPractices/github/actions/actions_can_approve_pull_requests.html
- GitHub Changelog (2022-05-03) — Prevent GitHub Actions from creating and approving pull requests:
  https://github.blog/changelog/2022-05-03-github-actions-prevent-github-actions-from-creating-and-approving-pull-requests/
- GitHub Docs — Managing GitHub Actions settings for a repository:
  https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
- GitHub REST — Actions permissions:
  https://docs.github.com/en/rest/actions/permissions
