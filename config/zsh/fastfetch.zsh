

# --- Greeting -----------------------------------------------

# kitty-direct sends only a file path, which the terminal must read
# itself: that fails under WSL (the terminal is a Windows program), in
# WezTerm, and over SSH (the file is on this machine, the terminal on
# another). iTerm's protocol sends the image data instead.
if [[ $TERM != dumb ]]; then
  if [[ $TERM_PROGRAM == WezTerm || -n $WSL_DISTRO_NAME || -n $SSH_CONNECTION ]]; then
    fastfetch --logo-type iterm
  else
    fastfetch
  fi
fi
