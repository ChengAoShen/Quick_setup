

# --- zoxide -------------------------------------------------
# Replaces `cd` itself; plain paths still work as before.

export _ZO_DOCTOR=0
eval "$(zoxide init --cmd cd zsh)"
