

# --- Greeting -----------------------------------------------

# WezTerm reads kitty-direct's file path on its own side, which fails
# under WSL; iTerm's protocol sends the image itself.
if [[ $TERM != dumb ]]; then
  if [[ $TERM_PROGRAM == WezTerm ]]; then
    fastfetch --logo-type iterm
  else
    fastfetch
  fi
fi
