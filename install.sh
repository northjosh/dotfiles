#!/usr/bin/env bash
#
# Symlink this repo's dotfiles into $HOME.
#
# Mapping is derived from the repo layout, so adding a tracked file is enough
# for it to be linked on the next run:
#
#   <repo>/zshrc              ->  ~/.zshrc
#   <repo>/config/nvim/*      ->  ~/.config/nvim/*
#
# Any existing real file is moved aside to <target>.backup.<timestamp> before
# being replaced. Existing symlinks that already point at this repo are left
# alone, so re-running is safe.
#
# Usage:
#   ./install.sh            link everything
#   ./install.sh --dry-run  show what would happen, change nothing

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]] && DRY_RUN=true

# Repo files that are not configuration and must never be linked into $HOME.
SKIP=(install.sh README.md LICENSE Brewfile .gitignore gitconfig)

linked=0 skipped=0 backed_up=0

log() { printf '%s\n' "$*"; }

link() {
  local src="$1" dest="$2"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    log "  ok       ${dest/#$HOME/~}"
    skipped=$((skipped + 1))
    return
  fi

  if $DRY_RUN; then
    if [[ -e "$dest" || -L "$dest" ]]; then
      log "  replace  ${dest/#$HOME/~}  (backup first)"
    else
      log "  link     ${dest/#$HOME/~}"
    fi
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    mv "$dest" "$dest.backup.$STAMP"
    log "  backup   ${dest/#$HOME/~}.backup.$STAMP"
    backed_up=$((backed_up + 1))
  fi

  ln -s "$src" "$dest"
  log "  link     ${dest/#$HOME/~}"
  linked=$((linked + 1))
}

is_skipped() {
  local name="$1"
  for s in "${SKIP[@]}"; do
    [[ "$name" == "$s" ]] && return 0
  done
  return 1
}

$DRY_RUN && log "Dry run - nothing will be changed."
log "Linking from $REPO"

# Top-level files become dotfiles in $HOME: zshrc -> ~/.zshrc
while IFS= read -r src; do
  name="$(basename "$src")"
  is_skipped "$name" && continue
  link "$src" "$HOME/.$name"
done < <(find "$REPO" -maxdepth 1 -type f | sort)

# Everything under config/ mirrors into ~/.config, preserving structure.
if [[ -d "$REPO/config" ]]; then
  while IFS= read -r src; do
    rel="${src#"$REPO"/config/}"
    link "$src" "$HOME/.config/$rel"
  done < <(find "$REPO/config" -type f | sort)
fi

if $DRY_RUN; then
  log "Dry run complete."
else
  log "Done. $linked linked, $skipped already correct, $backed_up backed up."
fi
