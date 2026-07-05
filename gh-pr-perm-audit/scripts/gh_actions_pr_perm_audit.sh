#!/usr/bin/env bash
# gh_actions_pr_perm_audit.sh  (v2 — security-first, 2026-05-25)
# Audit the per-repo GitHub setting
#   "Allow GitHub Actions to create and approve pull requests"
#   (REST: actions/permissions/workflow -> can_approve_pull_request_reviews)
#
# ROOT CAUSE / SECURITY POSTURE
#   can_approve_pull_request_reviews=false is the SECURE DEFAULT GitHub ships for
#   personal/org repos created after 2023-02. Setting it true lets a workflow
#   self-approve PRs via GITHUB_TOKEN and bypass required reviews (OpenSSF: do NOT
#   allow workflows to approve PRs). The one toggle conflates "create" and "approve",
#   so even repos that only need Actions to *create* PRs are forced to also grant
#   *approve*. Therefore: false = safe; true = an exposure unless intentional.
#
#   This tool treats `true` as the thing to justify, not `false`. Enabling is
#   allowlist-driven and manual; nothing is bulk-enabled. See:
#   ~/.claude/rules/gh-actions-pr-perm.md
#
# Usage:
#   gh_actions_pr_perm_audit.sh                 # audit (neutral table; flags risky repos)
#   gh_actions_pr_perm_audit.sh --owner NAME    # audit a specific owner
#   gh_actions_pr_perm_audit.sh --json          # machine-readable output
#   gh_actions_pr_perm_audit.sh --harden        # revert un-allowlisted true -> false (manual)
#   gh_actions_pr_perm_audit.sh --enable        # set allowlisted-but-false -> true (manual)
#   gh_actions_pr_perm_audit.sh --allowlist F   # allowlist file (default below)
#   gh_actions_pr_perm_audit.sh --include-forks # include forks (default: skip)
#   gh_actions_pr_perm_audit.sh --selftest      # offline self-test (no network)
#
# Allowlist: ~/.claude/config/gh-pr-perm-allowlist.txt
#   one entry per line, "owner/repo" or "repo", "#" comments allowed.
#   Repos listed here are INTENTIONALLY allowed to have Actions create+approve PRs.
#
# Exit codes: 0 = no un-allowlisted `true` (no exposure / all actions done)
#             1 = audit found un-allowlisted `true` repos (exposure to review)
#             2 = error / misuse
set -euo pipefail
export MSYS_NO_PATHCONV=1

DEFAULT_ALLOWLIST="${HOME}/.claude/config/gh-pr-perm-allowlist.txt"
FAILURE_LOG="${HOME}/.claude/failures.jsonl"

OWNER=""
MODE="audit"          # audit | harden | enable
JSON=0
INCLUDE_FORKS=0
ALLOWLIST_FILE="$DEFAULT_ALLOWLIST"
declare -a ALLOWLIST=()

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

# ---- secret redaction (verbatim idiom from codex_logged.sh; lib import + inline fallback) ----
redact() {
  local text="$1"
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
' "$text"
}

log_failure() {
  # log_failure <level> <exit_code> <detail>
  local level="$1" code="$2" detail="$3"
  LAB_FAILURES_SINK="$FAILURE_LOG" _shared_log_failure "gh-pr-perm" "$level" "exit_$code" "$detail" || true
}

die() { echo "ERROR: $1" >&2; log_failure error 2 "$1"; exit 2; }

# ---- allowlist ----
load_allowlist() {
  local f="$1"
  ALLOWLIST=()
  [ -f "$f" ] || return 0
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"                      # strip comments
    line="${line#"${line%%[![:space:]]*}"}" # ltrim
    line="${line%"${line##*[![:space:]]}"}" # rtrim
    [ -n "$line" ] && ALLOWLIST+=("$line")
  done < "$f"
  return 0
}

in_allowlist() {
  # in_allowlist <owner> <repo> ; matches "repo" or "owner/repo"
  local owner="$1" repo="$2" e
  for e in "${ALLOWLIST[@]:-}"; do
    [ "$e" = "$repo" ] && return 0
    [ "$e" = "${owner}/${repo}" ] && return 0
  done
  return 1
}

classify() {
  # classify <owner> <repo> <can_approve> -> echoes "STATUS<TAB>risk(0|1)"
  local owner="$1" repo="$2" ca="$3"
  if [ "$ca" = "true" ]; then
    if in_allowlist "$owner" "$repo"; then
      printf 'OK(allowlisted)\t0'
    else
      printf 'RISK(unexpected)\t1'
    fi
  elif [ "$ca" = "false" ]; then
    if in_allowlist "$owner" "$repo"; then
      printf 'INFO(allowlisted,disabled)\t0'
    else
      printf 'OK(secure-default)\t0'
    fi
  else
    printf 'ERR(unknown)\t0'
  fi
}

# ---- selftest (offline) ----
selftest() {
  local pass=0 total=0
  check() { total=$((total+1)); if [ "$2" = "$3" ]; then pass=$((pass+1)); else echo "FAIL[$1]: got '$2' want '$3'" >&2; fi; }

  # 1 redact: bearer token
  local r; r=$(redact "Authorization: Bearer abcdef0123456789ABCDEF")
  check redact-bearer "$r" "Authorization: Bearer ***"
  # 2 redact: sk- key
  r=$(redact "key sk-abcdef0123456789ABCD end"); check redact-sk "$r" "key sk-*** end"

  # allowlist fixtures
  ALLOWLIST=("alpha" "octo/bravo")
  # 3 in_allowlist by bare repo
  if in_allowlist octo alpha; then r=yes; else r=no; fi; check al-bare "$r" yes
  # 4 in_allowlist by owner/repo
  if in_allowlist octo bravo; then r=yes; else r=no; fi; check al-ownerrepo "$r" yes
  # 5 not in allowlist
  if in_allowlist octo charlie; then r=yes; else r=no; fi; check al-miss "$r" no

  # classify
  # 6 true + allowlisted -> OK
  r=$(classify octo alpha true | cut -f1); check cls-true-al "$r" "OK(allowlisted)"
  # 7 true + not allowlisted -> RISK
  r=$(classify octo charlie true); check cls-true-risk "$r" "$(printf 'RISK(unexpected)\t1')"
  # 8 false + not allowlisted -> secure default
  r=$(classify octo charlie false | cut -f1); check cls-false-default "$r" "OK(secure-default)"
  # 9 false + allowlisted -> INFO
  r=$(classify octo alpha false | cut -f1); check cls-false-info "$r" "INFO(allowlisted,disabled)"

  # 10 allowlist parser strips comments/blank/whitespace
  local tmp; tmp=$(mktemp)
  printf '# header\n\n  alpha  \nocto/bravo # inline\n\n' > "$tmp"
  load_allowlist "$tmp"; rm -f "$tmp"
  check al-parse-count "${#ALLOWLIST[@]}" "2"
  # 11 inline comment trimmed to bare value
  check al-parse-inline "${ALLOWLIST[1]}" "octo/bravo"
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
    --owner) OWNER="${2:-}"; shift 2 ;;
    --harden) MODE="harden"; shift ;;
    --enable) MODE="enable"; shift ;;
    --json) JSON=1; shift ;;
    --include-forks) INCLUDE_FORKS=1; shift ;;
    --allowlist) ALLOWLIST_FILE="${2:-}"; shift 2 ;;
    --selftest) selftest ;;
    --fix)
      echo "ERROR: --fix is removed (it bulk-enabled an approval-bypass risk)." >&2
      echo "Use --enable (allowlist-driven, opt-in) or --harden (revert to secure default)." >&2
      echo "See: ~/.claude/rules/gh-actions-pr-perm.md" >&2
      exit 2 ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) die "unknown arg: $1" ;;
  esac
done

# ---- preconditions (skipped for --selftest, which exits above) ----
command -v gh >/dev/null 2>&1 || die "gh not found on PATH"
gh auth status >/dev/null 2>&1 || die "gh not authenticated (run: gh auth login)"
[ -n "$OWNER" ] || OWNER=$(gh api user --jq .login) || die "could not resolve gh user"

load_allowlist "$ALLOWLIST_FILE"

fork_filter='.'
[ $INCLUDE_FORKS -eq 1 ] || fork_filter='map(select(.isFork | not))'

mapfile -t REPOS < <(gh repo list "$OWNER" --no-archived --limit 200 \
  --json name,isFork --jq "${fork_filter} | .[].name" 2>/dev/null | sort)
[ ${#REPOS[@]} -gt 0 ] || die "no repos found for owner '$OWNER'"

risk=0          # un-allowlisted true (exposure)
acted=0         # repos changed in harden/enable
declare -a JSON_ROWS=()

[ $JSON -eq 1 ] || printf "%-34s %-12s %-12s %-26s\n" "REPO" "defaultPerm" "canApprove" "STATUS"

for r in "${REPOS[@]}"; do
  out=$(gh api "repos/$OWNER/$r/actions/permissions/workflow" \
        --jq '[.default_workflow_permissions, (.can_approve_pull_request_reviews|tostring)] | @tsv' 2>/dev/null || true)
  dp=$(printf '%s' "$out" | cut -f1)
  ca=$(printf '%s' "$out" | cut -f2)
  if [ -z "${ca:-}" ]; then
    [ $JSON -eq 1 ] || printf "%-34s %-12s %-12s %-26s\n" "$r" "${dp:-?}" "?" "ERR(skip)"
    JSON_ROWS+=("$(printf '{"repo":"%s","default_workflow_permissions":"%s","can_approve":null,"status":"ERR(skip)","action":"none"}' "$r" "${dp:-}")")
    continue
  fi

  cls=$(classify "$OWNER" "$r" "$ca")
  status=$(printf '%s' "$cls" | cut -f1)
  is_risk=$(printf '%s' "$cls" | cut -f2)
  action="none"

  if [ "$MODE" = "harden" ] && [ "$ca" = "true" ] && ! in_allowlist "$OWNER" "$r"; then
    if gh api -X PUT "repos/$OWNER/$r/actions/permissions/workflow" \
         -f default_workflow_permissions="${dp:-read}" \
         -F can_approve_pull_request_reviews=false >/dev/null 2>&1; then
      action="hardened(true->false)"; acted=$((acted+1)); status="HARDENED"
    else
      action="harden-FAIL"; log_failure error 2 "harden PUT failed for $OWNER/$r"
    fi
  elif [ "$MODE" = "enable" ] && [ "$ca" = "false" ] && in_allowlist "$OWNER" "$r"; then
    if gh api -X PUT "repos/$OWNER/$r/actions/permissions/workflow" \
         -f default_workflow_permissions="${dp:-read}" \
         -F can_approve_pull_request_reviews=true >/dev/null 2>&1; then
      action="enabled(false->true)"; acted=$((acted+1)); status="ENABLED"
    else
      action="enable-FAIL"; log_failure error 2 "enable PUT failed for $OWNER/$r"
    fi
  fi

  [ "$is_risk" = "1" ] && [ "$MODE" = "audit" ] && risk=$((risk+1))

  if [ $JSON -eq 1 ]; then
    JSON_ROWS+=("$(printf '{"repo":"%s","default_workflow_permissions":"%s","can_approve":%s,"status":"%s","action":"%s"}' \
      "$r" "${dp:-}" "$ca" "$status" "$action")")
  else
    if [ "$action" = "none" ]; then
      printf "%-34s %-12s %-12s %-26s\n" "$r" "${dp:-?}" "$ca" "$status"
    else
      printf "%-34s %-12s %-12s %-26s\n" "$r" "${dp:-?}" "$ca" "$status ($action)"
    fi
  fi
done

if [ $JSON -eq 1 ]; then
  printf '{"owner":"%s","mode":"%s","risk_unallowlisted_true":%d,"acted":%d,"repos":[%s]}\n' \
    "$OWNER" "$MODE" "$risk" "$acted" "$(IFS=,; echo "${JSON_ROWS[*]:-}")"
else
  echo "---"
  case "$MODE" in
    harden) echo "owner=$OWNER  mode=harden  hardened=$acted" ;;
    enable) echo "owner=$OWNER  mode=enable  enabled=$acted" ;;
    audit)  echo "owner=$OWNER  mode=audit  risk(un-allowlisted true)=$risk" ;;
  esac
fi

if [ "$MODE" = "audit" ] && [ "$risk" -gt 0 ]; then
  [ $JSON -eq 1 ] || echo "Un-allowlisted repos allow Actions to approve PRs (review bypass risk). Run --harden to revert, or add to allowlist if intentional."
  log_failure warn 1 "audit: $risk un-allowlisted true repo(s) for owner=$OWNER"
  exit 1
fi
exit 0
