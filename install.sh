#!/usr/bin/env bash
#
# Quick_setup: an interactive installer for a zsh + CLI tools setup.
#
#   curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash
#
#   -y          take every default without asking
#   QS_REF=dev  fetch scripts and config files from another branch or tag
#
# This only picks the system: scripts/macos.sh (Homebrew) or
# scripts/linux.sh (official installers, conda-forge for the rest),
# which share scripts/common.sh and every file in config/.

set -uo pipefail

REPO=ChengAoShen/Quick_setup
SRC=https://raw.githubusercontent.com/$REPO/${QS_REF:-main}/scripts

# Everything runs inside main(), called on the last line, so under
# `curl | bash` nothing happens until the whole script has arrived.
main() {
  local os here tmp rc
  case $(uname -s) in
    Darwin) os=macos ;;
    Linux)  os=linux ;;
    *) echo "unsupported system: $(uname -s)" >&2; return 1 ;;
  esac

  # From a checkout, run its own copy.
  if [ -f "${BASH_SOURCE[0]:-}" ]; then
    here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    [ -f "$here/scripts/$os.sh" ] && { bash "$here/scripts/$os.sh" "$@"; return; }
  fi

  tmp=$(mktemp -d) || return 1
  if curl -fsSL -o "$tmp/common.sh" "$SRC/common.sh" &&
     curl -fsSL -o "$tmp/$os.sh" "$SRC/$os.sh"; then
    bash "$tmp/$os.sh" "$@"; rc=$?
  else
    echo "could not download scripts/$os.sh" >&2; rc=1
  fi
  rm -rf "$tmp"
  return $rc
}

# One line, so bash has read it all before main runs.
main "$@"; exit $?
