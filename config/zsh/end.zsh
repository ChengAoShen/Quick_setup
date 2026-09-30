

# --- Local additions ----------------------------------------
# API keys and anything specific to this machine. Never touched
# by install.sh, so it survives regenerating this file.

[[ -r ${ZDOTDIR:-$HOME}/local.zsh ]] && source ${ZDOTDIR:-$HOME}/local.zsh


# --- Plugins ------------------------------------------------
# Homebrew's copies on macOS, git clones under ~ on Linux; the first
# one found wins. Syntax highlighting has to be sourced last -- it
# wraps widgets and needs to see the final set.

for _p in zsh-autosuggestions zsh-syntax-highlighting; do
  for _d in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share} $HOME/.local/share/zsh/plugins; do
    [[ -r $_d/$_p/$_p.zsh ]] && { source $_d/$_p/$_p.zsh; break; }
  done
done
unset _p _d
