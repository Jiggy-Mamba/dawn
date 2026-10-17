#!/bin/bash
# Cloud-session setup: install gstack (required by CLAUDE.md and check-gstack.cjs)
# and Theme Check (the linter CI runs).
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GSTACK_DIR="$HOME/.claude/skills/gstack"

if [ ! -d "$GSTACK_DIR/bin" ]; then
  rm -rf "$GSTACK_DIR"
  git clone --quiet --single-branch --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_DIR"
  # --no-browser: the network policy blocks cdn.playwright.dev; the preinstalled
  # Chromium is used instead (GSTACK_CHROMIUM_PATH below).
  (cd "$GSTACK_DIR" && ./setup --team --no-browser --quiet </dev/null)
fi

# Point gstack /browse at the Chromium that ships with the cloud image.
if [ -n "${CLAUDE_ENV_FILE:-}" ] && [ -x /opt/pw-browsers/chromium ]; then
  echo 'export GSTACK_CHROMIUM_PATH=/opt/pw-browsers/chromium' >> "$CLAUDE_ENV_FILE"
fi

GEM_BIN="$(ruby -e 'print Gem.bindir')"
if [ ! -x "$GEM_BIN/theme-check" ]; then
  gem install --no-document --quiet theme-check
fi
# Ruby's gem bin dir is not on PATH in the cloud image.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$GEM_BIN:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
