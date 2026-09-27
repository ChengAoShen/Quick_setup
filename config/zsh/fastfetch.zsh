

# --- Greeting -----------------------------------------------

# kitty-direct sends only a file path, which the terminal must read
# itself: that fails under WSL (the terminal is a Windows program) and
# in WezTerm. iTerm's protocol sends the image data instead.
if [[ $TERM != dumb ]]; then
  if [[ $TERM_PROGRAM == WezTerm || -n $WSL_DISTRO_NAME ]]; then
    fastfetch --logo-type iterm
  else
    fastfetch
  fi
fi
