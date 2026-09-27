

# --- yazi ---------------------------------------------------
# `y` opens yazi and, on quit, cds to the directory it was in.

y() {
  local tmp cwd
  tmp=$(mktemp -t yazi-cwd.XXXXXX)
  yazi "$@" --cwd-file="$tmp"
  cwd=$(<"$tmp")
  [[ -n $cwd && $cwd != $PWD ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}
