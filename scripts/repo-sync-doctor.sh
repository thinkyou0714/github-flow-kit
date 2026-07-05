#!/usr/bin/env bash
# Multi-repository GitHub/local sync diagnosis.
# Based on the lightweight repository scanning pattern from dev-pulse-all.sh.

set -u

ROOT="C:/work"
REPO_DEPTH=4
FIND_MAX_DEPTH=$((REPO_DEPTH + 1))
EXCLUDE=""
MD=0
PROBE=0
PROBE_TIMEOUT="${REPO_SYNC_PROBE_TIMEOUT:-8}"
CANONICAL_OWNER="thinkyou0714"

usage() {
  cat <<'USAGE'
Usage: bash scripts/repo-sync-doctor.sh [--root <dir>] [--exclude a,b] [--md] [--probe]

Scans Git repositories under a root directory and reports GitHub/local sync status.

Options:
  --root <dir>    Root directory to scan. Default: C:/work
  --exclude a,b   Comma-separated path segment or basename patterns to skip.
  --md            Print a Markdown table.
  --probe         Run timed git ls-remote origin checks to detect dead remotes.
  -h, --help      Show this help.

Classification:
  A active        Needs reflection: dirty, ahead, behind, or missing upstream.
  B carve-out     Dirty and a changed file has mtime within the last 24 hours.
  C archive       Path contains _archive, lab-archive, _home-consolidated, or _worktrees.
  D out-of-scope  No reflection action detected.
  E dead-remote   --probe found origin unreachable/deleted.
  F fork          origin is not under github.com/thinkyou0714.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

require_git() {
  command -v git >/dev/null 2>&1 || fail "git command not found"
}

trim_spaces() {
  local value="${1:-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf "%s" "$value"
}

display_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1" 2>/dev/null || printf "%s" "$1"
  else
    printf "%s" "$1"
  fi
}

md_escape() {
  local value="${1:-}"
  value="${value//|/\\|}"
  printf "%s" "$value"
}

EXCLUDE_ARR=()
parse_excludes() {
  local raw pat
  EXCLUDE_ARR=()
  if [ -n "$EXCLUDE" ]; then
    IFS=',' read -r -a EXCLUDE_ARR <<< "$EXCLUDE"
    for raw in "${!EXCLUDE_ARR[@]}"; do
      pat="$(trim_spaces "${EXCLUDE_ARR[$raw]}")"
      EXCLUDE_ARR[$raw]="$pat"
    done
  fi
}

matches_exclude() {
  local repo="$1"
  local name norm pat
  name="$(basename "$repo")"
  norm="$(display_path "$repo")"
  norm="${norm//\\//}"

  for pat in "${EXCLUDE_ARR[@]:-}"; do
    [ -z "$pat" ] && continue
    if [[ "$name" == $pat ]]; then
      return 0
    fi
    case "/$norm/" in
      *"/$pat/"*) return 0 ;;
    esac
  done

  return 1
}

is_archive_path() {
  local repo="$1"
  local norm
  norm="$(display_path "$repo")"
  norm="${norm//\\//}"

  case "$norm" in
    *_archive*|*lab-archive*|*_home-consolidated*|*_worktrees*) return 0 ;;
  esac

  return 1
}

origin_owner() {
  local url="${1:-}"
  local lower path

  lower="$(printf "%s" "$url" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    git@github.com:*/*)
      path="${lower#git@github.com:}"
      ;;
    ssh://git@github.com/*/*)
      path="${lower#ssh://git@github.com/}"
      ;;
    https://github.com/*/*|http://github.com/*/*)
      path="${lower#*://github.com/}"
      ;;
    github.com/*/*)
      path="${lower#github.com/}"
      ;;
    *)
      printf ""
      return 1
      ;;
  esac

  path="${path%.git}"
  printf "%s" "${path%%/*}"
}

is_fork_origin() {
  local url="${1:-}"
  local owner

  [ -n "$url" ] || return 1
  owner="$(origin_owner "$url" || true)"
  if [ -z "$owner" ]; then
    return 0
  fi
  [ "$owner" != "$CANONICAL_OWNER" ]
}

has_recent_dirty() {
  local repo="$1"
  local entry status path path2 target

  while IFS= read -r -d '' entry; do
    [ -n "$entry" ] || continue
    status="${entry:0:2}"
    path="${entry:3}"

    case "$status" in
      R*|C*)
        if IFS= read -r -d '' path2; then
          [ -n "$path2" ] && path="$path2"
        fi
        ;;
    esac

    [ -n "$path" ] || continue
    target="$repo/$path"
    [ -e "$target" ] || continue

    if find "$target" -maxdepth 0 -mtime -1 -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  done < <(git -C "$repo" status --porcelain -z 2>/dev/null)

  return 1
}

run_probe() {
  local repo="$1"
  local pid elapsed

  if command -v timeout >/dev/null 2>&1; then
    timeout "${PROBE_TIMEOUT}s" git -C "$repo" ls-remote origin >/dev/null 2>&1
    return "$?"
  fi

  git -C "$repo" ls-remote origin >/dev/null 2>&1 &
  pid=$!
  elapsed=0

  while kill -0 "$pid" 2>/dev/null; do
    if [ "$elapsed" -ge "$PROBE_TIMEOUT" ]; then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  wait "$pid"
}

print_header() {
  if [ "$MD" -eq 1 ]; then
    printf "| class | path | branch | upstream | ahead | behind | dirty | origin |\n"
    printf "|---|---|---|---|---:|---:|---:|---|\n"
  else
    printf "CLASS\tPATH\tBRANCH\tUPSTREAM\tAHEAD\tBEHIND\tDIRTY\tORIGIN\n"
  fi
}

print_row() {
  local class="$1"
  local path="$2"
  local branch="$3"
  local upstream="$4"
  local ahead="$5"
  local behind="$6"
  local dirty="$7"
  local origin="$8"

  if [ "$MD" -eq 1 ]; then
    printf "| %s | %s | %s | %s | %s | %s | %s | %s |\n" \
      "$(md_escape "$class")" \
      "$(md_escape "$path")" \
      "$(md_escape "$branch")" \
      "$(md_escape "$upstream")" \
      "$ahead" \
      "$behind" \
      "$dirty" \
      "$(md_escape "$origin")"
  else
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
      "$class" "$path" "$branch" "$upstream" "$ahead" "$behind" "$dirty" "$origin"
  fi
}

classify_repo() {
  local repo="$1"
  local dirty="$2"
  local ahead="$3"
  local behind="$4"
  local upstream="$5"
  local branch="$6"
  local origin="$7"
  local dead="$8"

  if is_archive_path "$repo"; then
    printf "C:archive"
  elif [ "$dead" -eq 1 ]; then
    printf "E:dead-remote"
  elif is_fork_origin "$origin"; then
    printf "F:fork"
  elif [ "$dirty" -gt 0 ] && has_recent_dirty "$repo"; then
    printf "B:carve-out"
  elif [ "$dirty" -gt 0 ] || [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
    printf "A:active"
  elif [ -n "$origin" ] && [ -z "$upstream" ] && [ "$branch" != "(detached)" ]; then
    printf "A:active"
  else
    printf "D:out-of-scope"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      shift
      [ "$#" -gt 0 ] || fail "--root requires a directory"
      ROOT="$1"
      ;;
    --exclude)
      shift
      [ "$#" -gt 0 ] || fail "--exclude requires a comma-separated value"
      EXCLUDE="$1"
      ;;
    --md)
      MD=1
      ;;
    --probe)
      PROBE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

require_git
parse_excludes

[ -d "$ROOT" ] || fail "root does not exist: $ROOT"
ROOT_ABS="$(cd "$ROOT" 2>/dev/null && pwd -P)" || fail "could not resolve root: $ROOT"

total=0
active_count=0
dead_count=0

print_header

while IFS= read -r -d '' git_marker; do
  repo="$(dirname "$git_marker")"

  matches_exclude "$repo" && continue
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || continue

  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\r' || true)"
  [ -n "$branch" ] || branch="?"
  [ "$branch" = "HEAD" ] && branch="(detached)"

  upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null | tr -d '\r' || true)"
  upstream_display="$upstream"
  [ -n "$upstream_display" ] || upstream_display="none"

  ahead=0
  behind=0
  if [ -n "$upstream" ]; then
    counts="$(git -C "$repo" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null || printf "0\t0")"
    behind="$(printf "%s" "$counts" | awk '{print $1}')"
    ahead="$(printf "%s" "$counts" | awk '{print $2}')"
    [ -n "$behind" ] || behind=0
    [ -n "$ahead" ] || ahead=0
  fi

  dirty="$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  [ -n "$dirty" ] || dirty=0

  origin_url="$(git -C "$repo" remote get-url origin 2>/dev/null | tr -d '\r' || true)"

  dead=0
  if [ "$PROBE" -eq 1 ] && [ -n "$origin_url" ]; then
    if ! run_probe "$repo"; then
      dead=1
    fi
  fi

  class="$(classify_repo "$repo" "$dirty" "$ahead" "$behind" "$upstream" "$branch" "$origin_url" "$dead")"
  case "$class" in
    A:*) active_count=$((active_count + 1)) ;;
    E:*) dead_count=$((dead_count + 1)) ;;
  esac

  print_row \
    "$class" \
    "$(display_path "$repo")" \
    "$branch" \
    "$upstream_display" \
    "$ahead" \
    "$behind" \
    "$dirty" \
    "$origin_url"

  total=$((total + 1))
done < <(find "$ROOT_ABS" -mindepth 1 -maxdepth "$FIND_MAX_DEPTH" \
  \( -type d -name .git -print0 -prune \) -o \
  \( -type f -name .git -print0 \) 2>/dev/null)

if [ "$MD" -eq 1 ]; then
  printf "\nSummary: total=%s / active(A)=%s / dead-remote(E)=%s\n" \
    "$total" "$active_count" "$dead_count"
else
  printf "\nsummary: total=%s / active(A)=%s / dead-remote(E)=%s\n" \
    "$total" "$active_count" "$dead_count"
fi
