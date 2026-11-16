#!/bin/sh
# Single entry point for all pre-flight checks. Runs from the pre-commit hook
# (.githooks/pre-commit) and from CI (.github/workflows/ci.yml), so local and
# CI results always match.
#
# Section 1 is stack-agnostic and needs only git + POSIX sh.
# Section 2 is where each project wires in its own lint / format / type / test.
#
# Usage: scripts/check.sh            # check every tracked file
#        scripts/check.sh --staged   # check only files staged for commit
set -eu

cd "$(git rev-parse --show-toplevel)"

MODE=all
[ "${1:-}" = "--staged" ] && MODE=staged

FAILED=0
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAILED=$((FAILED + 1)); }
pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
skip() { printf '  \033[33mSKIP\033[0m %s\n' "$1"; }

# Paths excluded from the whitespace / line-ending checks (generated or vendored).
EXCLUDES=":(exclude)**/node_modules/** :(exclude)**/vendor/** :(exclude)**/*.min.* \
:(exclude)**/*lock.json :(exclude)**/*.lock :(exclude)**/*-lock.yaml :(exclude)**/go.sum"

# List text files, one per line (git decides what is binary via .gitattributes).
list_text_files() {
  # shellcheck disable=SC2086
  if [ "$MODE" = staged ]; then
    # numstat prints "-<TAB>-" for binary files.
    git diff --cached --numstat --no-renames --diff-filter=ACMR -- . $EXCLUDES \
      | awk -F '\t' '$1 != "-" { print $3 }'
  else
    git grep -I -l -e '' -- . $EXCLUDES 2>/dev/null || true
  fi
}

# Read file content as it will be committed (index) in staged mode, else working tree.
show() {
  if [ "$MODE" = staged ]; then git show ":$1"; else cat -- "$1"; fi
}

echo "Running checks ($MODE)..."

# ---------------------------------------------------------------------------
# 1. Stack-agnostic checks
# ---------------------------------------------------------------------------
FILES=$(list_text_files)
# Iterate per line so paths with spaces survive.
OLD_IFS=$IFS
IFS='
'

# 1a. Line endings: LF only (Windows scripts are allowed CRLF, see .gitattributes).
BAD=""
for f in $FILES; do
  case "$f" in *.bat|*.cmd|*.ps1) continue ;; esac
  if show "$f" | grep -q "$(printf '\r')"; then BAD="$BAD $f"; fi
done
if [ -n "$BAD" ]; then fail "line endings (CRLF found):$BAD"; else pass "line endings"; fi

# 1b. Trailing whitespace (Markdown exempt: two trailing spaces = line break).
BAD=""
for f in $FILES; do
  case "$f" in *.md) continue ;; esac
  if show "$f" | grep -q '[[:blank:]]$'; then BAD="$BAD $f"; fi
done
if [ -n "$BAD" ]; then fail "trailing whitespace:$BAD"; else pass "trailing whitespace"; fi

# 1c. Final newline.
BAD=""
for f in $FILES; do
  [ -n "$(show "$f" | tail -c 1)" ] && BAD="$BAD $f"
done
if [ -n "$BAD" ]; then fail "missing final newline:$BAD"; else pass "final newline"; fi

# 1d. Secret scan (optional locally; CI always runs gitleaks).
if command -v gitleaks >/dev/null 2>&1; then
  if [ "$MODE" = staged ]; then
    if gitleaks git --pre-commit --staged --redact --no-banner >/dev/null 2>&1; then
      pass "secrets (gitleaks)"
    else
      fail "secrets (gitleaks): run 'gitleaks git --pre-commit --staged -v' for details"
    fi
  else
    if gitleaks dir . --redact --no-banner >/dev/null 2>&1; then
      pass "secrets (gitleaks)"
    else
      fail "secrets (gitleaks): run 'gitleaks dir . -v' for details"
    fi
  fi
else
  skip "secrets (gitleaks not installed; CI will scan)"
fi

IFS=$OLD_IFS

# ---------------------------------------------------------------------------
# 2. Project checks: wire in the stack's own tools here.
#    Each step must exit non-zero on failure. Examples:
#
#    Node (pnpm + oxc):   run_step "lint/format/type/test" pnpm run check
#    Python (ruff):       run_step "ruff" ruff check . && run_step "format" ruff format --check .
#    PHP:                 run_step "test" composer test
#    Go:                  run_step "vet" go vet ./... && run_step "test" go test ./...
# ---------------------------------------------------------------------------
run_step() {
  name=$1; shift
  log=$(mktemp)
  if "$@" >"$log" 2>&1; then pass "$name"; else
    fail "$name"; cat "$log"
  fi
  rm -f "$log"
}

# (no project checks yet)

# ---------------------------------------------------------------------------
echo
if [ "$FAILED" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$FAILED check(s) failed."
  exit 1
fi
