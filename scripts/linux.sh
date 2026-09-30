#!/usr/bin/env bash
#
# Quick_setup for Linux. install.sh runs this; from a checkout it
# also runs on its own:
#
#   bash scripts/linux.sh [-y]
#
# CLI tools come from conda-forge through micromamba, which needs no
# root, has the same recent versions on every distro (apt would lag
# years behind and rename half the tools), and updates them all with
# one command. uv is the exception: its own installer, which
# `uv self update` keeps current. sudo is only ever used for what
# has to be the system's own: the login shell (chsh, and the zsh it
# points at) and the C compiler.

set -uo pipefail   # no -e: one failed step should not stop the rest
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

export PATH=$BIN:$HOME/.cargo/bin:$PATH

# micromamba 1.x defaulted to ~/micromamba; keep using it if it is there.
MAMBA_ROOT=${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}
[ -z "${MAMBA_ROOT_PREFIX:-}" ] && [ -d "$HOME/micromamba" ] && MAMBA_ROOT=$HOME/micromamba
ENV=$MAMBA_ROOT/envs/tools

# From conda-forge. cmd  conda-package  description
TOOLS='
zsh        zsh             Z shell
git        git             version control
starship   starship        prompt
zoxide     zoxide          smarter cd
fzf        fzf             fuzzy finder
eza        eza             modern ls
bat        bat             cat with highlighting
fd         fd-find         modern find
rg         ripgrep         fast grep
jq         jq              JSON processor
delta      git-delta       git diff pager
nvim       nvim            editor
tmux       tmux            terminal multiplexer
gh         gh              GitHub CLI
lazygit    lazygit         git TUI
btop       btop            system monitor
atuin      atuin           searchable shell history
direnv     direnv          per-directory env
just       just            command runner
fastfetch  fastfetch       system info greeting
yazi       yazi            terminal file manager
node       nodejs          JavaScript runtime, npm
tree-sitter tree-sitter-cli parser CLI for Neovim
cc         gcc             C compiler, only without sudo
unzip      unzip           zip extractor
'

# From each project's own installer (inst_<cmd> below). Their conda
# package has the same name, which matters when replacing one.
OFFICIAL='
uv         Python packages
'

pkg_of() {  # pkg_of <cmd>
  echo "$TOOLS" | while read -r c p _; do [ "$c" = "$1" ] && echo "$p"; done
}

# Linked into ~/.local/bin from the conda-forge env, as an older
# version of this script did for everything.
from_env() {
  case $(readlink "$BIN/$1" 2>/dev/null) in "$MAMBA_ROOT"/*) return 0 ;; esac
  return 1
}

can_sudo() {
  has sudo && { sudo -n true 2>/dev/null || id -Gn | grep -qwE 'sudo|wheel|admin'; }
}
# chsh cannot help an LDAP account, which is not in /etc/passwd.
can_chsh() { grep -q "^$(id -un):" /etc/passwd && can_sudo; }

# Print the state of one tool; status 0 when it should be offered.
# Without root, whatever sits in /usr/bin can be years old (tmux
# and zsh too old for this config, say), so it is offered anyway.
check() {  # check <cmd> <description> [official]
  if [ -n "${3:-}" ] && from_env "$1"; then
    old "$1  ${D}(conda-forge copy, replaced by the official one)$N"; return 0
  fi
  case $(command -v "$1" 2>/dev/null) in
    /usr/bin/*|/bin/*) old "$1  ${D}(system copy, may be old)$N"; return 0 ;;
    ?*) ok "$1"; return 1 ;;
    *)  no "$1  $D$2$N"; return 0 ;;
  esac
}

pick() {  # pick <var> <missing...>: ask all at once, then one by one
  local var=$1 c got=; shift
  [ $# -gt 0 ] || return 0
  if ask "Install all of: $*?" y; then got=" $*"
  else for c in "$@"; do ask "  $c?" y && got="$got $c"; done
  fi
  eval "$var=\$got"
}


main() {
header linux

say "Package manager"
if has micromamba; then ok "micromamba"
else
  no "micromamba"
  ask "Install micromamba to ~/.local/bin?" y && DO="$DO mamba"
fi
local can_pkg c desc missing=
can_pkg=$( { has micromamba || inlist mamba "$DO"; } && echo 1)

say "CLI tools  ${D}(conda-forge)$N"
while read -r c _ desc; do
  [ -n "$c" ] || continue
  [ "$c" = cc ] && continue   # asked about below
  check "$c" "$desc" && missing="$missing $c"
done <<EOF
$TOOLS
EOF
if [ -z "$missing" ]; then :
elif [ -z "$can_pkg" ]; then warn "no micromamba, skipping these"
else pick PICK $missing
fi

# The system compiler is what CUDA and other native builds expect,
# and it brings make and the libc headers; a conda gcc ahead of it
# on PATH does not. conda-forge's is only for an account without sudo.
say "C compiler"
if has cc; then ok "cc  ${D}($(command -v cc))$N"
elif can_sudo; then
  no "cc"
  ask "Install the system one (sudo: build-essential, gcc or base-devel)?" y && DO="$DO cc"
elif [ -n "$can_pkg" ]; then
  no "cc  ${D}(no sudo for the system one)$N"
  ask "Install gcc from conda-forge instead?" y && PICK="$PICK cc"
fi
[ -n "$PICK" ] && DO="$DO tools"

say "CLI tools  ${D}(own installer)$N"
missing=
while read -r c desc; do
  [ -n "$c" ] || continue
  check "$c" "$desc" official && missing="$missing $c"
done <<EOF
$OFFICIAL
EOF
pick OPICK $missing
[ -n "$OPICK" ] && DO="$DO official"

say "zsh plugins"
if [ -d "$PLUGIN_DIR/zsh-autosuggestions" ] && [ -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
  ok "autosuggestions, syntax-highlighting"
else
  no "autosuggestions, syntax-highlighting"
  will git && ask "Install them (git clone)?" y && DO="$DO plugins"
fi

ask_common

# chsh with sudo when it can work; otherwise ~/.bashrc hands over.
SHELL_HOW=bashrc
say "Login shell"
if [ "$(basename "${SHELL:-}")" = zsh ]; then
  # A zsh under ~ (the conda-forge one) locks you out of SSH the
  # day that env breaks or home is not mounted yet.
  case $SHELL in
    "$HOME"/*)
      if can_chsh; then
        no "zsh, but from ~${SHELL#$HOME}"
        ask "Switch to the system zsh (sudo, installs it if needed)?" y &&
          { DO="$DO shell"; SHELL_HOW=chsh; }
      else ok "zsh  ${D}(~${SHELL#$HOME}, no sudo for a system one)$N"
      fi ;;
    *) ok "zsh" ;;
  esac
elif grep -q 'Quick_setup' "$HOME/.bashrc" 2>/dev/null; then ok "bash hands over to zsh"
else
  no "login shell is ${SHELL:-unknown}"
  if can_chsh; then
    echo "  1) sudo chsh  make the system zsh the real login shell"
    echo "  2) .bashrc    interactive bash execs zsh, no sudo"
    local how
    if [ $YES = 1 ]; then how=1; else
      printf '  choose, or n to skip [1] '; read -r how || how=
    fi
    case ${how:-1} in
      1) DO="$DO shell"; SHELL_HOW=chsh ;;
      2) DO="$DO shell" ;;
    esac
  else
    ask "Make interactive bash exec zsh via ~/.bashrc?" y && DO="$DO shell"
  fi
fi

run_plan
}


do_mamba() {
  local plat
  case $(uname -m) in
    x86_64)        plat=linux-64 ;;
    aarch64|arm64) plat=linux-aarch64 ;;
    *) warn "no micromamba build for $(uname -m)"; return 1 ;;
  esac
  local bin=$BIN/micromamba
  mkdir -p "$BIN"
  # The bare binary from GitHub needs no tar or bzip2, which minimal
  # images often lack; micro.mamba.pm's tarball is the fallback.
  if ! curl -fsSL -o "$bin" "https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-$plat"; then
    warn "GitHub download failed, trying micro.mamba.pm"
    curl -fsSL "https://micro.mamba.pm/api/micromamba/$plat/latest" |
      tar -xj -C "$BIN" --strip-components=1 bin/micromamba
  fi
  chmod 755 "$bin" 2>/dev/null
  "$bin" --version >/dev/null 2>&1 || { rm -f "$bin"; warn "micromamba does not run on this system"; return 1; }
  ok "micromamba $("$bin" --version)"
}

# A separate env that is never activated; only the wanted binaries
# are linked into ~/.local/bin, so its openssl and friends do not
# shadow the system ones.
do_tools() {
  local c l pkgs= sub=create
  for c in $PICK; do pkgs="$pkgs $(pkg_of "$c")"; done
  [ -n "$pkgs" ] || return 0
  [ -d "$ENV" ] && sub=install
  micromamba $sub -y -r "$MAMBA_ROOT" -n tools -c conda-forge $pkgs || return 1
  for c in $PICK; do
    case $c in
      yazi) c="yazi ya" ;;         # ya is yazi's plugin manager
      node) c="node npm npx" ;;
      cc)   c="cc gcc" ;;
    esac
    for l in $c; do
      [ -x "$ENV/bin/$l" ] && ln -sfn "$ENV/bin/$l" "$BIN/$l"
    done
  done
  return 0
}

do_cc() {
  if has apt-get; then sudo apt-get install -y build-essential
  elif has dnf; then sudo dnf install -y gcc gcc-c++ make
  elif has pacman; then sudo pacman -S --needed --noconfirm base-devel
  else warn "no apt-get, dnf or pacman to install it with"; return 1
  fi
}

# Each one writes its binary straight into ~/.local/bin and is told
# to leave shell files alone; .zshrc already has the PATH.
inst_uv() {
  curl -LsSf https://astral.sh/uv/install.sh |
    env UV_INSTALL_DIR="$BIN" UV_NO_MODIFY_PATH=1 sh
}

do_official() {
  local c link failed= drop=
  mkdir -p "$BIN"
  for c in $OPICK; do
    printf '  %s-> %s%s\n' "$B" "$c" "$N"
    # Installers copy onto the path, which would write through the
    # link into the env; unlink first, and put it back on failure.
    link=
    if from_env "$c"; then link=$(readlink "$BIN/$c"); rm -f "$BIN/$c"; fi
    if "inst_$c"; then
      ok "$c"
      [ -n "$link" ] && drop="$drop $c"
    else
      warn "$c failed"
      [ -n "$link" ] && [ ! -e "$BIN/$c" ] && ln -s "$link" "$BIN/$c"
      failed="$failed $c"
    fi
  done
  # uvx came along with uv, from both places.
  if inlist uv "$drop"; then
    case $(readlink "$BIN/uvx" 2>/dev/null) in "$MAMBA_ROOT"/*) rm -f "$BIN/uvx" ;; esac
  fi
  [ -n "$drop" ] && micromamba remove -y -r "$MAMBA_ROOT" -n tools $drop >/dev/null 2>&1
  [ -z "$failed" ]
}

do_plugins() {
  local r
  mkdir -p "$PLUGIN_DIR"
  for r in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ -d "$PLUGIN_DIR/$r" ]; then git -C "$PLUGIN_DIR/$r" pull -q --ff-only
    else git clone -q --depth 1 "https://github.com/zsh-users/$r" "$PLUGIN_DIR/$r"
    fi || return 1
    ok "$r"
  done
}

do_shell() {
  local z
  if [ $SHELL_HOW = chsh ]; then
    # Only the system zsh: one under ~ breaks login whenever home is
    # not mounted yet, or its conda-forge env is broken.
    for z in /usr/bin/zsh /bin/zsh; do [ -x "$z" ] && break; done
    if [ ! -x "$z" ]; then
      if has apt-get; then sudo apt-get install -y zsh
      elif has dnf; then sudo dnf install -y zsh
      elif has pacman; then sudo pacman -S --noconfirm zsh
      fi
      for z in /usr/bin/zsh /bin/zsh; do [ -x "$z" ] && break; done
    fi
    [ -x "$z" ] || { warn "no system zsh, and could not install one"; return 1; }
    grep -qx "$z" /etc/shells || echo "$z" | sudo tee -a /etc/shells >/dev/null || return 1
    sudo chsh -s "$z" "$(id -un)"
    return
  fi
  z=$(command -v zsh) || { warn "zsh not found"; return 1; }
  # Only interactive shells, so scp, rsync and VS Code Remote keep
  # getting the bash they expect.
  cat >>"$HOME/.bashrc" <<EOF

# >>> Quick_setup: hand interactive bash over to zsh >>>
case \$- in *i*)
  if [ -z "\$ZSH_VERSION" ] && [ "\$TERM" != dumb ] && [ -z "\$VSCODE_INJECTION" ] && [ -x "$z" ]; then
    exec "$z" -l
  fi ;;
esac
# <<< Quick_setup <<<
EOF
  warn "open a second session to check it works before closing this one"
}

main; exit $?
