

# --- micromamba ---------------------------------------------
# `conda` is aliased unless a real conda is around.

export MAMBA_ROOT_PREFIX=${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}
eval "$(micromamba shell hook --shell zsh 2>/dev/null)"
(( $+commands[conda] )) || alias conda=micromamba
