#!/usr/bin/env bash
# Symlink every skill in this repo into ~/.claude/skills/ so Claude Code loads them.
# Re-runnable: a later `git pull` updates symlinked skills automatically.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$DEST"

installed=0
skipped=0

# Each skill is skills/<category>/<skill-name>/
for skill_dir in "$REPO_DIR"/skills/*/*/; do
  name="$(basename "$skill_dir")"
  target="$DEST/$name"

  if [ -L "$target" ]; then
    # already a symlink — repoint it (handles a moved repo) and move on
    ln -sfn "${skill_dir%/}" "$target"
    echo "↻ updated  $name"
    installed=$((installed + 1))
  elif [ -e "$target" ]; then
    echo "⚠ skipped  $name — a non-symlink already exists at $target (left untouched)"
    skipped=$((skipped + 1))
  else
    ln -s "${skill_dir%/}" "$target"
    echo "✓ linked   $name"
    installed=$((installed + 1))
  fi
done

echo
echo "Done: $installed installed/updated, $skipped skipped."
echo "Open Claude Code and type '/' to confirm the skills are available."
