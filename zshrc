export ZSH="$HOME/.oh-my-zsh"
export EDITOR='nvim'

# Prompt is handled by starship (below), so no omz theme.
ZSH_THEME=""
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="%F{yellow}hollup...%f"
DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(git docker zsh-autosuggestions )

# Skip oh-my-zsh's compaudit permission check on completion dirs (~12ms/startup).
ZSH_DISABLE_COMPFIX="true"

source $ZSH/oh-my-zsh.sh

# Tool init scripts (`eval "$(foo init zsh)"`) cost ~50ms/startup in subprocess
# spawns. Cache their output and re-generate only when the tool binary changes.
# To force a refresh after upgrading config: rm -rf ~/.cache/zsh-init
__zinit_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init"
[[ -d $__zinit_cache ]] || mkdir -p $__zinit_cache
zcache_eval() {
  local name=$1; shift
  local bin=${commands[$1]} f=$__zinit_cache/$name.zsh
  [[ -n $bin ]] || return 0
  if [[ ! -s $f || $bin -nt $f ]]; then
    "$@" >| $f.tmp 2>/dev/null && mv -f $f.tmp $f || { rm -f $f.tmp; "$@" | source /dev/stdin; return; }
  fi
  source $f
}

zcache_eval starship starship init zsh

# Starship computes git status in-process (gitoxide), and the untracked-file
# walk is by far the prompt's biggest cost in large repos (sentry: 103ms -> 48ms).
# GIT_CONFIG_* overrides config for starship's queries only, so `git status` on
# the command line still reports untracked files everywhere.
# Trade-off: the prompt no longer shows the untracked marker.
__starship_fast() {
  GIT_CONFIG_COUNT=1 \
  GIT_CONFIG_KEY_0=status.showUntrackedFiles \
  GIT_CONFIG_VALUE_0=no \
  command starship "$@"
}
# Rewrite starship's own PROMPT/RPROMPT to route through the wrapper, rather
# than restating its argument list (which changes between starship versions).
# Replacing the bare path also covers the quoted form some init versions emit,
# since 'fn' in command position still resolves to the function.
PROMPT=${PROMPT//${commands[starship]}/__starship_fast}
RPROMPT=${RPROMPT//${commands[starship]}/__starship_fast}

zcache_eval zoxide zoxide init zsh

export PATH=$PATH://Users/josh/dev/sonar-scanner/bin:/Users/josh/dev/sonarqube/bin/macosx-universal-64:/Users/josh/dev/codeql:/Users/josh/dev/flutter/bin:/Users/josh/.pub-cache/bin

export CHROME_EXECUTABLE="/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
export PATH="$HOME/.local/share/pnpm:$PATH"

# pnpm
export PNPM_HOME="/Users/josh/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/Users/josh/.bun/_bun" ] && source "/Users/josh/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

. "$HOME/.atuin/bin/env"

# open buffer line in EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

#atuin
zcache_eval atuin atuin init zsh

# Set up fzf key bindings and fuzzy completion
zcache_eval fzf fzf --zsh

export ENABLE_TOOL_SEARCH=true

# ngrok completion is the slowest init (~20ms); cached like the rest.
zcache_eval ngrok ngrok completion

# Must stay LAST: zsh-syntax-highlighting wraps every widget defined before it.
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
