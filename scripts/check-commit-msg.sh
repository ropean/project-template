#!/bin/sh
# Reject commit messages that contain CJK text: commit messages must be English.
# Emoji, accented names (e.g. in Co-Authored-By trailers) and symbols are allowed.
#
# Usage: scripts/check-commit-msg.sh <message-file>          # commit-msg hook
#        scripts/check-commit-msg.sh --range <base>..<head>  # CI: every commit in range
# Requires perl (ships with git on macOS, Linux and Git for Windows).
set -eu

# Han, Hiragana, Katakana, Hangul, Bopomofo, CJK and fullwidth punctuation.
FIND_CJK='
  while (<STDIN>) {
    next if /^#/;   # git comment lines in the editor template
    if (/[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}\p{Bopomofo}\x{3000}-\x{303F}\x{FF00}-\x{FFEF}]/) {
      print "    line $.: $_"; $bad = 1;
    }
  }
  exit($bad ? 1 : 0);
'

check() { perl -CS -e "$FIND_CJK"; }

if [ "${1:-}" = "--range" ]; then
  FAILED=0
  for sha in $(git rev-list --no-merges "$2"); do
    if ! out=$(git log -1 --format=%B "$sha" | check); then
      echo "Commit $(git log -1 --format='%h %s' "$sha") has a non-English message:"
      echo "$out"
      FAILED=1
    fi
  done
  [ "$FAILED" -eq 0 ] && echo "Commit messages: OK" || exit 1
else
  if ! out=$(check < "$1"); then
    echo "Commit message must be in English (see CLAUDE.md). Offending lines:"
    echo "$out"
    exit 1
  fi
fi
