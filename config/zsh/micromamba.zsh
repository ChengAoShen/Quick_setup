

# --- micromamba ---------------------------------------------
# `conda` is aliased unless a real conda is around.

# micromamba 1.x defaulted to ~/micromamba; keep using it if it is there.
if [[ -z $MAMBA_ROOT_PREFIX ]]; then
  if [[ -d $HOME/micromamba ]]; then export MAMBA_ROOT_PREFIX=$HOME/micromamba
  else export MAMBA_ROOT_PREFIX=$HOME/.local/share/mamba
  fi
fi
eval "$(micromamba shell hook --shell zsh 2>/dev/null)"
(( $+commands[conda] )) || alias conda=micromamba
