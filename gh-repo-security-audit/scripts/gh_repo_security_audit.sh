#!/usr/bin/env bash
# gh_repo_security_audit.sh  (2026-05-26)
# OpenSSF-aligned, read-only GitHub repo/Actions security audit across an account.
# Sibling to gh_actions_pr_perm_audit.sh (which covers the PR self-approve toggle only).
#
# CHECKS (per repo, via gh api; GET-only unless --enable-dependabot):
#   - Token-Permissions: default_workflow_permissions should be "read" (least privilege).
#   - Allowed actions policy: "all" vs "selected"/"local_only" (OpenSSF: restrict).
#   - Branch-Protection: default branch protected? (compensating control for bot tokens)
#   - Secret scanning + push protection: should be enabled on PUBLIC repos (free).
#   - Dependabot vulnerability alerts: should be ON (free on all repos).
#   - (best-effort, local clones) Dangerous-Workflow triggers + unpinned action refs.
#
# SEVERITY:
#   WARN (trips exit 1) = a fixable security gap: dependabot OFF, default perms "write",
#                         or a PUBLIC repo without secret scanning.
#   INFO (no exit trip)  = opinionated hardening: no branch protection, allowed_actions "all".
#
# Usage:
#   gh_repo_security_audit.sh                 # audit table (GET-only)
#   gh_repo_security_audit.sh --owner NAME    # audit a specific owner (default: gh user)
#   gh_repo_security_audit.sh --json          # machine-readable
#   gh_repo_security_audit.sh --local DIR     # extra glob root for clone heuristics (repeatable)
#   gh_repo_security_audit.sh --enable-dependabot  # MANUAL opt-in: turn ON Dependabot alerts
#                                                  #   where OFF (safe, secure-direction PUT)
#   gh_repo_security_audit.sh --include-forks
#   gh_repo_security_audit.sh --selftest      # offline self-test (no network)
#
# Mutations: only --enable-dependabot (PUT /vulnerability-alerts; reversible via DELETE).
#   Branch protection / allowed_actions / SHA-pinning are NEVER auto-applied (human-gated).
#
# Exit: 0 = no WARN-level findings / 1 = WARN findings (or --selftest fail) / 2 = error.
# Doc: ~/.claude/rules/gh-repo-security.md
set -euo pipefail
export MSYS_NO_PATHCONV=1

FAILURE_LOG="${HOME}/.claude/failures.jsonl"
OWNER=""
JSON=0
INCLUDE_FORKS=0
ENABLE_DEPENDABOT=0
declare -a LOCAL_ROOTS=("/c/work" "${HOME}")

load_failures_lib() {
  local failures_lib
  failures_lib="$(dirname "$0")/_failures_log.sh"
  if [ -f "$failures_lib" ]; then
    . "$failures_lib"
    eval "$(declare -f log_failure | sed '1s/log_failure/_shared_log_failure/')"
  else
    _shared_log_failure() {
      mkdir -p "$(dirname "${LAB_FAILURES_SINK:-$HOME/.claude/failures.jsonl}")" 2>/dev/null || true
      printf '{"ts":"%s","hook":"%s","level":"%s","category":"%s","detail":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "$3" "$(printf '%s' "$4" | tr -d '"\\' | tr '\r\n' '  ')" >> "${LAB_FAILURES_SINK:-$HOME/.claude/failures.jsonl}" 2>/dev/null || true
    }
  fi
}
load_failures_lib

# ---- secret redaction (idiom from gh_actions_pr_perm_audit.sh; lib import + inline fallback) ----
redact() {
  python3 -c '
import sys, pathlib
sys.path.insert(0, str(pathlib.Path.home() / ".claude" / "lib"))
try:
    from secret_redact import redact
except ImportError:
    import re
    PATTERNS = [
        (re.compile(r"(?i)(authorization\s*:\s*bearer\s+)[A-Za-z0-9._\-]+"), r"\1***"),
        (re.compile(r"(?i)(bearer\s+)[A-Za-z0-9._\-]{16,}"), r"\1***"),
        (re.compile(r"\bsk-[A-Za-z0-9_\-]{16,}\b"), "sk-***"),
        (re.compile(r"\bxai-[A-Za-z0-9_\-]{16,}\b"), "xai-***"),
        (re.compile(r"(?i)(api[_\-]?key\s*[=:]\s*)[\"\047]?[A-Za-z0-9_\-]{16,}[\"\047]?"), r"\1***"),
        (re.compile(r"(?i)(x-api-key\s*[=:]\s*)[\"\047]?[A-Za-z0-9_\-]{16,}[\"\047]?"), r"\1***"),
        (re.compile(r"(?i)(token\s*[=:]\s*)[\"\047]?[A-Za-z0-9_\-\.]{20,}[\"\047]?"), r"\1***"),
        (re.compile(r"://[^@/\s]+:[^@/\s]+@"), "://***:***@"),
    ]
    def redact(t):
        if not t: return ""
        for p, r in PATTERNS:
            t = p.sub(r, t)
        return t
print(redact(sys.argv[1]), end="")
' "$1"
}

log_failure() {
  # log_failure <level> <exit_code> <detail>
  local level="$1" code="$2" detail="$3"
  LAB_FAILURES_SINK="$FAILURE_LOG" _shared_log_failure "gh-repo-sec" "$level" "exit_$code" "$detail" || true
}

die() { echo "ERROR: $1" >&2; log_failure error 2 "$1"; exit 2; }

# ---- pure classifiers (unit-testable) ----
classify_dependabot() { [ "$1" = "on" ] && echo "OK" || echo "WARN"; }       # off => WARN
classify_perm()       { [ "$1" = "write" ] && echo "WARN" || echo "OK"; }    # write => WARN
classify_branch()     { [ "$1" = "yes" ] && echo "OK" || echo "INFO"; }      # none => INFO
classify_allowed()    { [ "$1" = "all" ] && echo "INFO" || echo "OK"; }      # all => INFO
classify_secret() {                                                          # public+!enabled => WARN
  local vis="$1" status="$2"
  if [ "$vis" = "public" ]; then [ "$status" = "enabled" ] && echo "OK" || echo "WARN"; else echo "OK"; fi
}

# ---- selftest (offline) ----
selftest() {
  local pass=0 total=0 r
  check() { total=$((total+1)); if [ "$2" = "$3" ]; then pass=$((pass+1)); else echo "FAIL[$1]: got '$2' want '$3'" >&2; fi; }

  r=$(redact "Authorization: Bearer abcdef0123456789ABCDEF"); check redact-bearer "$r" "Authorization: Bearer ***"
  r=$(redact "key sk-abcdef0123456789ABCD end");              check redact-sk "$r" "key sk-*** end"
  r=$(redact "tok xai-abcdef0123456789ABCD end");             check redact-xai "$r" "tok xai-*** end"

  check dep-off   "$(classify_dependabot off)" "WARN"
  check dep-on    "$(classify_dependabot on)"  "OK"
  check perm-write "$(classify_perm write)"    "WARN"
  check perm-read  "$(classify_perm read)"     "OK"
  check branch-none "$(classify_branch none)"  "INFO"
  check branch-yes  "$(classify_branch yes)"   "OK"
  check allowed-all "$(classify_allowed all)"  "INFO"
  check allowed-sel "$(classify_allowed selected)" "OK"
  check secret-pub-off "$(classify_secret public disabled)" "WARN"
  check secret-pub-on  "$(classify_secret public enabled)"  "OK"
  check secret-priv    "$(classify_secret private n/a)"     "OK"
  local tmp_failures old_failure_log py
  py=python3; command -v python3 >/dev/null 2>&1 || py=python
  tmp_failures=$(mktemp); old_failure_log="$FAILURE_LOG"; FAILURE_LOG="$tmp_failures"
  log_failure warn 1 'quoted "detail" and backslash \ path'
  if "$py" -c 'import json,sys; r=json.loads(sys.stdin.readline()); assert all(k in r for k in ("ts","hook","level","category","detail"))' < "$tmp_failures" 2>/dev/null; then r=yes; else r=no; fi
  check failure-json "$r" yes
  FAILURE_LOG="$old_failure_log"; rm -f "$tmp_failures"

  echo "selftest: ${pass}/${total} PASS"
  [ "$pass" -eq "$total" ] && exit 0 || exit 1
}

# ---- arg parse ----
while [ $# -gt 0 ]; do
  case "$1" in
    --owner) [ $# -ge 2 ] || die "--owner requires a value"; OWNER="$2"; shift 2 ;;
    --json) JSON=1; shift ;;
    --include-forks) INCLUDE_FORKS=1; shift ;;
    --enable-dependabot) ENABLE_DEPENDABOT=1; shift ;;
    --local) [ $# -ge 2 ] || die "--local requires a value"; LOCAL_ROOTS+=("$2"); shift 2 ;;
    --selftest) selftest ;;
    -h|--help) sed -n '2,33p' "$0"; exit 0 ;;
    *) die "unknown arg: $1" ;;
  esac
done

# ---- preconditions ----
command -v gh >/dev/null 2>&1 || die "gh not found on PATH"
gh auth status >/dev/null 2>&1 || die "gh not authenticated (run: gh auth login)"
[ -n "$OWNER" ] || OWNER=$(gh api user --jq .login) || die "could not resolve gh user"

fork_filter='.'
[ $INCLUDE_FORKS -eq 1 ] || fork_filter='map(select(.isFork | not))'
mapfile -t REPOS < <(gh repo list "$OWNER" --no-archived --limit 200 \
  --json name,isFork --jq "${fork_filter} | .[].name" 2>/dev/null | sort)
[ ${#REPOS[@]} -gt 0 ] || die "no repos found for owner '$OWNER'"

warn=0; enabled=0
declare -a JSON_ROWS=()
[ $JSON -eq 1 ] || printf "%-20s %-7s %-7s %-8s %-9s %-7s %-7s\n" \
  "REPO" "vis" "defPrm" "allowed" "branchPr" "secScn" "depBot"

for r in "${REPOS[@]}"; do
  # one snapshot of the repo object (visibility + default branch + secret scanning)
  snap=$(gh api "repos/$OWNER/$r" --jq '[.visibility, .default_branch, (.security_and_analysis.secret_scanning.status // "n/a")] | @tsv' 2>/dev/null || true)
  IFS=$'\t' read -r vis db ss <<<"$snap"
  dp=$(gh api "repos/$OWNER/$r/actions/permissions/workflow" --jq '.default_workflow_permissions' 2>/dev/null || true)
  al=$(gh api "repos/$OWNER/$r/actions/permissions" --jq '.allowed_actions // "all"' 2>/dev/null || true)
  if gh api "repos/$OWNER/$r/branches/${db:-main}/protection" >/dev/null 2>&1; then bp="yes"; else bp="none"; fi
  if gh api "repos/$OWNER/$r/vulnerability-alerts" >/dev/null 2>&1; then dep="on"; else dep="off"; fi

  # optional safe mutation
  act_dep=""
  if [ $ENABLE_DEPENDABOT -eq 1 ] && [ "$dep" = "off" ]; then
    if gh api -X PUT "repos/$OWNER/$r/vulnerability-alerts" >/dev/null 2>&1; then
      dep="on"; act_dep=" (ENABLED)"; enabled=$((enabled+1))
    else
      act_dep=" (ENABLE-FAIL)"; log_failure error 2 "enable-dependabot PUT failed for $OWNER/$r"
    fi
  fi

  c_dep=$(classify_dependabot "$dep")
  c_perm=$(classify_perm "${dp:-read}")
  c_secret=$(classify_secret "${vis:-private}" "${ss:-n/a}")
  # count WARN-level
  for c in "$c_dep" "$c_perm" "$c_secret"; do [ "$c" = "WARN" ] && warn=$((warn+1)); done

  if [ $JSON -eq 1 ]; then
    JSON_ROWS+=("$(printf '{"repo":"%s","visibility":"%s","default_workflow_permissions":"%s","allowed_actions":"%s","branch_protection":"%s","secret_scanning":"%s","dependabot_alerts":"%s","warn_dependabot":"%s","warn_perm":"%s","warn_secret":"%s"}' \
      "$r" "${vis:-}" "${dp:-}" "${al:-}" "$bp" "${ss:-}" "$dep" "$c_dep" "$c_perm" "$c_secret")")
  else
    printf "%-20s %-7s %-7s %-8s %-9s %-7s %-7s%s\n" \
      "$r" "${vis:-?}" "${dp:-?}" "${al:-all}" "$bp" "${ss:-n/a}" "$dep" "$act_dep"
  fi
done

# ---- local-clone heuristics (best-effort; printed in table mode only) ----
if [ $JSON -eq 0 ]; then
  echo "---"
  shopt -s nullglob
  wf_files=()
  for root in "${LOCAL_ROOTS[@]}"; do
    for f in "$root"/*/.github/workflows/*.y*ml; do wf_files+=("$f"); done
  done
  shopt -u nullglob
  dwf=0; total=0; sha=0
  if [ ${#wf_files[@]} -gt 0 ]; then
    dwf=$( { grep -lE 'pull_request_target|workflow_run' "${wf_files[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')
    total=$( { grep -hoE 'uses:[[:space:]]*[A-Za-z0-9._/-]+@[A-Za-z0-9._-]+' "${wf_files[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')
    sha=$(  { grep -hoE 'uses:[[:space:]]*[A-Za-z0-9._/-]+@[0-9a-f]{40}'    "${wf_files[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')
  fi
  echo "local-clone heuristics (best-effort): workflow files=${#wf_files[@]}  dangerous-trigger files=${dwf}  unpinned action refs=$((total - sha))/${total}"
fi

if [ $JSON -eq 1 ]; then
  printf '{"owner":"%s","warn_findings":%d,"dependabot_enabled_now":%d,"repos":[%s]}\n' \
    "$OWNER" "$warn" "$enabled" "$(IFS=,; echo "${JSON_ROWS[*]:-}")"
else
  echo "---"
  echo "owner=$OWNER  WARN(fixable)=$warn  dependabot_enabled_now=$enabled"
  [ $ENABLE_DEPENDABOT -eq 0 ] && [ "$warn" -gt 0 ] && \
    echo "Fix Dependabot gaps with: $0 --enable-dependabot   (branch protection / allowed_actions / SHA-pinning stay manual — see rules doc)"
fi

if [ "$warn" -gt 0 ]; then
  log_failure warn 1 "audit: $warn WARN-level finding(s) for owner=$OWNER"
  exit 1
fi
exit 0
