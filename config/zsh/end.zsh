

# --- Local additions ----------------------------------------
# API keys and anything specific to this machine. Never touched
# by install.sh, so it survives regenerating this file.

[[ -r ${ZDOTDIR:-$HOME}/local.zsh ]] && source ${ZDOTDIR:-$HOME}/local.zsh


# --- Plugins ------------------------------------------------
# Syntax highlighting has to be sourced last -- it wraps widgets
# and needs to see the final set.

_zplug=$HOME/.local/share/zsh/plugins
[[ -r $_zplug/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source $_zplug/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r $_zplug/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source $_zplug/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unset _zplug
