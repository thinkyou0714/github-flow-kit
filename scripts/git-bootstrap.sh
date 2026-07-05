#!/usr/bin/env bash
# Idempotently check or apply the shared Git global configuration.

set -u

MODE="check"

CONFIG_KEYS=(
  "core.longpaths"
  "core.autocrlf"
  "push.autoSetupRemote"
  "fetch.prune"
  "pull.ff"
  "init.defaultBranch"
)

CONFIG_VALUES=(
  "true"
  "false"
  "true"
  "true"
  "only"
  "main"
)

usage() {
  cat <<'USAGE'
Usage: bash scripts/git-bootstrap.sh [--check|--apply|--selftest]

Idempotently manages this Git global config set:
  core.longpaths=true
  core.autocrlf=false
  push.autoSetupRemote=true
  fetch.prune=true
  pull.ff=only
  init.defaultBranch=main

Options:
  --check     Show current value -> target value without changing anything.
              This is the default and exits 0 even when differences exist.
  --apply     Apply the target values with git config --global.
  --selftest  Run an isolated temporary-HOME verification and print PASS/FAIL.
  -h, --help  Show this help.

Notes:
  core.editor is intentionally not touched.
  core.autocrlf=false matches the jj repository policy in C:/work/WORKSPACE_PATHS.md;
  end-of-line behavior is expected to be controlled by .gitattributes.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

require_git() {
  command -v git >/dev/null 2>&1 || fail "git command not found"
}

config_get() {
  git config --global --get "$1" 2>/dev/null || true
}

display_value() {
  if [ -n "${1:-}" ]; then
    printf "%s" "$1"
  else
    printf "(unset)"
  fi
}

print_header() {
  printf "%-24s  %-18s  %-18s  %s\n" "KEY" "BEFORE" "AFTER" "RESULT"
  printf "%-24s  %-18s  %-18s  %s\n" "---" "------" "-----" "------"
}

run_config() {
  local mode="$1"
  local changed=0
  local failed=0
  local i key target before after result

  require_git
  print_header

  for i in "${!CONFIG_KEYS[@]}"; do
    key="${CONFIG_KEYS[$i]}"
    target="${CONFIG_VALUES[$i]}"
    before="$(config_get "$key")"

    if [ "$before" = "$target" ]; then
      after="$before"
      result="ok(unchanged)"
    elif [ "$mode" = "apply" ]; then
      changed=1
      if git config --global "$key" "$target" >/dev/null 2>&1; then
        after="$(config_get "$key")"
        if [ "$after" = "$target" ]; then
          result="updated"
        else
          result="failed"
          failed=1
        fi
      else
        after="$target"
        result="failed"
        failed=1
      fi
    else
      changed=1
      after="$target"
      result="diff(pending)"
    fi

    printf "%-24s  %-18s  %-18s  %s\n" \
      "$key" "$(display_value "$before")" "$(display_value "$after")" "$result"
  done

  if [ "$failed" -ne 0 ]; then
    echo "summary: one or more settings failed." >&2
    return 1
  fi

  if [ "$changed" -eq 0 ]; then
    echo "summary: all settings already match target."
  elif [ "$mode" = "apply" ]; then
    echo "summary: target settings applied."
  else
    echo "summary: differences shown above; no changes made."
  fi
}

run_selftest() {
  local tmp rc i key target actual editor

  require_git
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/git-bootstrap.XXXXXX")" || fail "could not create temp directory"

  (
    set -u
    export HOME="$tmp/home"
    export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
    mkdir -p "$HOME" || exit 1

    run_config check >/dev/null || exit 1
    run_config apply >/dev/null || exit 1
    run_config check >/dev/null || exit 1
    run_config apply >/dev/null || exit 1

    for i in "${!CONFIG_KEYS[@]}"; do
      key="${CONFIG_KEYS[$i]}"
      target="${CONFIG_VALUES[$i]}"
      actual="$(config_get "$key")"
      if [ "$actual" != "$target" ]; then
        echo "FAIL: $key expected '$target' but got '$(display_value "$actual")'" >&2
        exit 1
      fi
    done

    editor="$(config_get core.editor)"
    if [ -n "$editor" ]; then
      echo "FAIL: core.editor was unexpectedly set to '$editor'" >&2
      exit 1
    fi
  )
  rc=$?

  rm -rf "$tmp"

  if [ "$rc" -eq 0 ]; then
    echo "PASS: git-bootstrap selftest"
  else
    echo "FAIL: git-bootstrap selftest" >&2
  fi

  return "$rc"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      MODE="check"
      ;;
    --apply)
      MODE="apply"
      ;;
    --selftest)
      MODE="selftest"
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

case "$MODE" in
  check|apply)
    run_config "$MODE" || exit 1
    ;;
  selftest)
    run_selftest || exit 1
    ;;
  *)
    fail "unsupported mode: $MODE"
    ;;
esac
