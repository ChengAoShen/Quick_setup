#!/usr/bin/env bash
#
# Quick_setup: an interactive installer for a zsh + CLI tools setup.
#
#   curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash
#
#   -y          take every default without asking
#   QS_REF=dev  fetch config files from another branch or tag
#
# It looks at the machine, asks what to do, then does it in order.
# Every file it replaces is backed up first. Written for bash 3.2,
# which is what macOS ships.

set -uo pipefail   # no -e: one failed step should not stop the rest

REPO=ChengAoShen/Quick_setup
RAW=https://raw.githubusercontent.com/$REPO/${QS_REF:-main}/config
BACKUP=$HOME/.local/state/quick_setup/backup-$(date +%Y%m%d-%H%M%S)
PLUGIN_DIR=$HOME/.local/share/zsh/plugins
# micromamba 1.x defaulted to ~/micromamba; keep using it if it is there.
MAMBA_ROOT=${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}
[ -z "${MAMBA_ROOT_PREFIX:-}" ] && [ -d "$HOME/micromamba" ] && MAMBA_ROOT=$HOME/micromamba
ZDIR=$HOME/.config/zsh

YES=0
for a in "$@"; do
  case $a in
    -y|--yes) YES=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

# Run from a checkout, use its config/ instead of downloading.
LOCAL=
if [ -f "${BASH_SOURCE[0]:-}" ]; then
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  [ -d "$here/config" ] && LOCAL=$here/config
fi

# Without a terminal there is nobody to ask.
TTY=1
{ : </dev/tty; } 2>/dev/null || { TTY=0; YES=1; }

if [ -t 1 ]; then
  B=$'\033[1m' G=$'\033[32m' R=$'\033[31m' Y=$'\033[33m' D=$'\033[2m' N=$'\033[0m'
else
  B= G= R= Y= D= N=
fi

say()  { printf '\n%s==> %s%s\n' "$B" "$*" "$N"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
no()   { printf '  %s✗%s %s\n' "$R" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*" >&2; }
has()  { command -v "$1" >/dev/null 2>&1; }
inlist() { case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }

# ask "question" y|n   -> status 0 for yes
ask() {
  local hint='[Y/n]' ans
  [ "$2" = n ] && hint='[y/N]'
  if [ $YES = 1 ]; then ans=$2; else
    printf '  %s %s ' "$1" "$hint"
    read -r ans </dev/tty || ans=
  fi
  case ${ans:-$2} in [Yy]*) return 0 ;; esac
  return 1
}

# Fetch one file from config/ to stdout.
fetch() {
  if [ -n "$LOCAL" ]; then cat "$LOCAL/$1"; else curl -fsSL "$RAW/$1"; fi
}

# Put new content at a path, backing up whatever differs there.
place() {  # place <tmpfile> <dest>
  if [ -e "$2" ] && cmp -s "$1" "$2"; then rm -f "$1"; ok "~${2#$HOME} unchanged"; return; fi
  if [ -e "$2" ] || [ -L "$2" ]; then
    mkdir -p "$BACKUP"
    mv "$2" "$BACKUP/$(printf '%s' "${2#$HOME/}" | tr / _)"
  fi
  mkdir -p "$(dirname "$2")"
  chmod 644 "$1"   # mktemp makes it 600
  mv "$1" "$2"
  ok "~${2#$HOME}"
}

get() {  # get <config path> <dest>
  local t; t=$(mktemp)
  fetch "$1" >"$t" || { rm -f "$t"; warn "could not fetch $1"; return 1; }
  place "$t" "$2"
}

find_brew() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$b" ]; then BREW=$b; eval "$("$b" shellenv)"; return 0; fi
  done
  return 1
}


# Everything below runs inside main(), called on the last line, so
# under `curl | bash` nothing happens until the whole script has
# arrived. main then points stdin at the terminal: otherwise any
# installer it runs could read the rest of the script as input.
main() {
if [ $TTY = 1 ]; then exec </dev/tty; else exec </dev/null; fi


# === 1. Look at the machine ===========================================

# bob keeps nvim in ~/.local/share/bob on Linux and in Application
# Support on macOS.
export PATH="$HOME/.local/bin:$HOME/.local/share/bob/nvim-bin:$HOME/Library/Application Support/bob/nvim-bin:$PATH"
BREW=
find_brew

case $(uname -s) in
  Darwin) OS=mac ;;
  Linux)  OS=linux ;;
  *) echo "unsupported system: $(uname -s)" >&2; exit 1 ;;
esac
ARCH=$(uname -m)

printf '%sQuick_setup%s  %s %s' "$B" "$N" "$OS" "$ARCH"
[ -n "$LOCAL" ] && printf '  %s(local config: %s)%s' "$D" "$LOCAL" "$N"
echo

# MODE is how packages get installed: Homebrew on macOS, micromamba
# on Linux. micromamba needs no root and gives the same recent
# versions on every distro, where apt would lag years behind and
# rename half the tools. sudo is only ever used, if at all, for chsh.
MODE=brew
[ $OS = linux ] && MODE=mamba

# cmd  brew-package  conda-package  description   (- : installed another way)
TOOLS='
zsh        zsh        zsh         Z shell
git        git        git         version control
starship   starship   starship    prompt
zoxide     zoxide     zoxide      smarter cd
fzf        fzf        fzf         fuzzy finder
eza        eza        eza         modern ls
bat        bat        bat         cat with highlighting
fd         fd         fd-find     modern find
rg         ripgrep    ripgrep     fast grep
delta      git-delta  git-delta   git diff pager
nvim       -          -           editor, via bob
tmux       tmux       tmux        terminal multiplexer
gh         gh         gh          GitHub CLI
lazygit    lazygit    lazygit     git TUI
btop       btop       btop        system monitor
atuin      atuin      atuin       searchable shell history
direnv     direnv     direnv      per-directory env
just       just       just        command runner
uv         uv         uv          Python packages
fastfetch  fastfetch  fastfetch   system info greeting
'

pkg_of() {  # pkg_of <cmd>
  echo "$TOOLS" | while read -r c pb pc _; do
    [ "$c" = "$1" ] && { [ $MODE = brew ] && echo "$pb" || echo "$pc"; }
  done
}


# === 2. Ask ===========================================================

DO=          # the steps to run, in the order they will run
PICK=        # tools to install
will() { has "$1" || inlist "$1" "$PICK"; }   # present once we are done

say "Package manager"
if [ $MODE = brew ]; then
  if [ -n "$BREW" ]; then ok "Homebrew ($BREW)"
  else
    no "Homebrew"
    ask "Install Homebrew?" y && DO="$DO brew"
  fi
  CAN_PKG=$( { [ -n "$BREW" ] || inlist brew "$DO"; } && echo 1)
else
  if has micromamba; then ok "micromamba"
  else
    no "micromamba"
    ask "Install micromamba to ~/.local/bin?" y && DO="$DO mamba"
  fi
  CAN_PKG=$( { has micromamba || inlist mamba "$DO"; } && echo 1)
fi

say "CLI tools"
missing=
while read -r c _ _ desc; do
  [ -n "$c" ] || continue
  # Without root, whatever sits in /usr/bin can be years old (tmux
  # and zsh too old for this config, say), so it is offered anyway.
  case $OS:$(command -v "$c" 2>/dev/null) in
    linux:/usr/bin/*|linux:/bin/*)
      printf '  %s~%s %s  %s(system copy, may be old)%s\n' "$Y" "$N" "$c" "$D" "$N"
      missing="$missing $c" ;;
    *:?*) ok "$c" ;;
    *)    no "$c  $D$desc$N"; missing="$missing $c" ;;
  esac
done <<EOF
$TOOLS
EOF
if [ -z "$missing" ]; then :
elif [ -z "$CAN_PKG" ]; then warn "no package manager, skipping tools"
elif ask "Install all of:$missing?" y; then PICK=$missing
else
  for c in $missing; do ask "  $c?" y && PICK="$PICK $c"; done
fi
[ -n "$(echo " $PICK " | sed 's/ nvim / /' | tr -d ' ')" ] && DO="$DO tools"
inlist nvim "$PICK" && DO="$DO bob"

say "zsh plugins"
if [ -d "$PLUGIN_DIR/zsh-autosuggestions" ] && [ -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
  ok "autosuggestions, syntax-highlighting"
else
  no "autosuggestions, syntax-highlighting"
  will git && ask "Install them?" y && DO="$DO plugins"
fi

say "Claude Code"
if has claude; then ok "claude"
else
  no "claude"
  ask "Install Claude Code?" n && DO="$DO claude"
fi

say "Config files"
echo "  ${D}replaced files are backed up to ~${BACKUP#$HOME}$N"
ask "zsh: .zshenv + .zshrc generated from what is installed?" y && DO="$DO zshrc"
will starship  && ask "starship.toml?" y && DO="$DO starship"
will tmux      && ask "tmux.conf?" y && DO="$DO tmux"
will fastfetch && ask "fastfetch config?" y && DO="$DO fastfetch"
{ has claude || inlist claude "$DO"; } && ask "Claude Code settings.json?" y && DO="$DO claude_cfg"
if will nvim && will git; then
  if [ -e "$HOME/.config/nvim" ]; then ok "~/.config/nvim exists, leaving it"
  else ask "Neovim config (github.com/ChengAoShen/nvim)?" y && DO="$DO nvim"
  fi
fi

# Linux only: macOS has had zsh as the default since Catalina.
# chsh with sudo when it can work; otherwise ~/.bashrc hands over.
# chsh cannot help an LDAP account, which is not in /etc/passwd.
SHELL_HOW=bashrc
if [ $OS = linux ]; then
  say "Login shell"
  if [ "$(basename "${SHELL:-}")" = zsh ]; then ok "zsh"
  elif grep -q 'Quick_setup' "$HOME/.bashrc" 2>/dev/null; then ok "bash hands over to zsh"
  else
    no "login shell is ${SHELL:-unknown}"
    if grep -q "^$(id -un):" /etc/passwd && has sudo &&
       { sudo -n true 2>/dev/null || id -Gn | grep -qwE 'sudo|wheel|admin'; }; then
      echo "  1) sudo chsh  make zsh the real login shell"
      echo "  2) .bashrc    interactive bash execs zsh, no sudo"
      if [ $YES = 1 ]; then pick=1; else
        printf '  choose, or n to skip [1] '; read -r pick </dev/tty || pick=
      fi
      case ${pick:-1} in
        1) DO="$DO shell"; SHELL_HOW=chsh ;;
        2) DO="$DO shell" ;;
      esac
    else
      ask "Make interactive bash exec zsh via ~/.bashrc?" y && DO="$DO shell"
    fi
  fi
fi

if [ -z "$DO" ]; then say "Nothing to do"; exit 0; fi
say "Plan"
for s in $DO; do
  case $s in
    tools) echo "  - tools:$PICK" ;;
    *)     echo "  - $s" ;;
  esac
done
ask "Go ahead?" y || exit 0


# === 3. Do ============================================================

do_brew() {
  sudo -v || return 1   # Homebrew's non-interactive mode needs sudo cached
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &&
    find_brew
}

do_mamba() {
  local plat
  case $ARCH in
    x86_64)        plat=linux-64 ;;
    aarch64|arm64) plat=linux-aarch64 ;;
    *) warn "no micromamba build for $ARCH"; return 1 ;;
  esac
  mkdir -p "$HOME/.local/bin"
  curl -fsSL "https://micro.mamba.pm/api/micromamba/$plat/latest" |
    tar -xj -C "$HOME/.local/bin" --strip-components=1 bin/micromamba
}

do_tools() {
  local c p pkgs=
  for c in $PICK; do
    p=$(pkg_of "$c")
    [ "$p" = - ] || pkgs="$pkgs $p"
  done
  [ -n "$pkgs" ] || return 0
  if [ $MODE = brew ]; then
    brew install $pkgs
  else
    # A separate env that is never activated; only the wanted binaries
    # are linked into ~/.local/bin, so its openssl and friends do not
    # shadow the system ones.
    local env=$MAMBA_ROOT/envs/tools sub=create
    [ -d "$env" ] && sub=install
    micromamba $sub -y -r "$MAMBA_ROOT" -n tools -c conda-forge $pkgs || return 1
    for c in $PICK; do
      [ -x "$env/bin/$c" ] && ln -sfn "$env/bin/$c" "$HOME/.local/bin/$c"
    done
  fi
}

# Neovim comes from bob, so every machine can be put on the same
# version with `bob use <version>`. Same release binary on both
# systems; brew has bob but conda-forge does not.
do_bob() {
  local a t
  if ! has bob; then
    case $OS-$ARCH in
      mac-arm64)    a=macos-arm ;;
      mac-x86_64)   a=macos-x86_64 ;;
      linux-x86_64) a=linux-x86_64 ;;
      linux-aarch64|linux-arm64) a=linux-arm ;;
      *) warn "no bob build for $OS $ARCH"; return 1 ;;
    esac
    t=$(mktemp -d)
    curl -fsSL -o "$t/bob.zip" "https://github.com/MordechaiHadad/bob/releases/latest/download/bob-$a.zip" || return 1
    if has unzip; then unzip -q "$t/bob.zip" -d "$t"
    else python3 -m zipfile -e "$t/bob.zip" "$t"
    fi || { warn "need unzip or python3 to unpack bob"; return 1; }
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$t/bob-$a/bob" "$HOME/.local/bin/bob" || return 1
    rm -rf "$t"
  fi
  bob use stable
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

do_claude() { curl -fsSL https://claude.ai/install.sh | bash; }

# .zshrc is assembled from config/zsh/: the base, then one snippet per
# tool that is actually on this machine, so nothing refers to a
# command that is not there.
do_zshrc() {
  local t s
  get zshenv "$HOME/.zshenv" || return 1
  t=$(mktemp)
  {
    echo "# Generated by Quick_setup on $(date +%F). Re-running install.sh"
    echo "# regenerates it; keep your own additions in local.zsh."
    echo
    if [ -n "$BREW" ]; then
      printf '# Homebrew: PATH, MANPATH and completions. Before compinit.\n'
      printf 'eval "$(%s shellenv zsh)"\n\n' "$BREW"
    fi
    fetch zsh/base.zsh
    for s in micromamba nvim eza bat starship zoxide fzf direnv atuin; do
      has "$s" && fetch "zsh/$s.zsh"
    done
    fetch zsh/end.zsh
    has fastfetch && fetch zsh/fastfetch.zsh
  } >"$t" || { rm -f "$t"; return 1; }
  place "$t" "$ZDIR/.zshrc"
  # An older version of this setup called it secrets.zsh.
  if [ ! -e "$ZDIR/local.zsh" ] && [ -e "$ZDIR/secrets.zsh" ]; then
    mv "$ZDIR/secrets.zsh" "$ZDIR/local.zsh" && ok "~${ZDIR#$HOME}/secrets.zsh -> local.zsh"
  fi
  if [ ! -e "$ZDIR/local.zsh" ]; then
    printf '# Machine-local: API keys and anything else for this host only.\n' >"$ZDIR/local.zsh"
    chmod 600 "$ZDIR/local.zsh"
    ok "~${ZDIR#$HOME}/local.zsh"
  fi
}

do_starship()  { get starship.toml "$HOME/.config/starship.toml"; }
do_fastfetch() {
  get fastfetch/config.jsonc "$HOME/.config/fastfetch/config.jsonc" &&
    get fastfetch/marin.png "$HOME/.config/fastfetch/marin.png"
}
do_claude_cfg() { get claude-settings.json "$HOME/.claude/settings.json"; }
do_nvim() { git clone -q https://github.com/ChengAoShen/nvim "$HOME/.config/nvim"; }

do_tmux() {
  # tmux reads ~/.tmux.conf first when it exists.
  if [ -e "$HOME/.tmux.conf" ]; then
    mkdir -p "$BACKUP" && mv "$HOME/.tmux.conf" "$BACKUP/.tmux.conf"
  fi
  get tmux.conf "$HOME/.config/tmux/tmux.conf"
}

do_shell() {
  local z
  if [ $SHELL_HOW = chsh ]; then
    # Prefer the system zsh: one under ~ breaks login whenever home
    # is not mounted yet.
    for z in /usr/bin/zsh /bin/zsh "$(command -v zsh)"; do [ -x "$z" ] && break; done
    [ -x "$z" ] || { warn "zsh not found"; return 1; }
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

FAILED=
for s in $DO; do
  say "$s"
  "do_$s" || { warn "$s failed"; FAILED="$FAILED $s"; }
done

say "Done"
[ -d "$BACKUP" ] && echo "  backups: $BACKUP"
if [ -n "$FAILED" ]; then
  no "failed:$FAILED  (re-run to retry)"
  exit 1
fi
echo "  open a new terminal to start using it"
}

# One line, so bash has read it all before main swaps stdin away.
main "$@"; exit $?
