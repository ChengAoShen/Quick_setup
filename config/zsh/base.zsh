# --- PATH ---------------------------------------------------
# Highest precedence first, in front of whatever is already set.

typeset -U path
path=(
  $HOME/.local/bin                  # personal scripts, uv tools
  $HOME/.cargo/bin                  # cargo-installed binaries
  $path
)


# --- History ------------------------------------------------
# 50k commands, shared across sessions, deduped, and skipping
# anything typed with a leading space.

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE \
       HIST_REDUCE_BLANKS EXTENDED_HISTORY


# --- Shell behavior -----------------------------------------
# Bare directory name cds into it, with a directory stack.

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS NO_BEEP


# --- Completion ---------------------------------------------
# Selectable menu, case-insensitive matching, grouped sections.
# compinit's security check is the slow part of startup, so it
# runs once a day and the cached dump is trusted in between.

autoload -Uz compinit

_zdump=${ZDOTDIR:-$HOME}/.zcompdump
if [[ -f $_zdump && -z $_zdump(#qN.mh+24) ]]; then
  compinit -C -d $_zdump
else
  compinit -d $_zdump
fi
unset _zdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'


# --- Aliases ------------------------------------------------

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
