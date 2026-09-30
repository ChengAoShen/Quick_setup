# Quick_setup: what macos.sh and linux.sh share -- the helpers, the
# steps that are the same on both systems, and the loop that runs
# the plan. Sourced by them, never run on its own. Written for bash
# 3.2, which is what macOS ships.

REPO=ChengAoShen/Quick_setup
RAW=https://raw.githubusercontent.com/$REPO/${QS_REF:-main}/config
BACKUP=$HOME/.local/state/quick_setup/backup-$(date +%Y%m%d-%H%M%S)
PLUGIN_DIR=$HOME/.local/share/zsh/plugins
ZDIR=$HOME/.config/zsh
BIN=$HOME/.local/bin

YES=0
for a in "$@"; do
  case $a in
    -y|--yes) YES=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

# Run from a checkout, use its config/ instead of downloading.
# install.sh runs a downloaded copy from a temp dir, which has none.
LOCAL=
QS_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[ -f "$QS_ROOT/install.sh" ] && [ -d "$QS_ROOT/config" ] && LOCAL=$QS_ROOT/config

# Without a terminal there is nobody to ask.
TTY=1
{ : </dev/tty; } 2>/dev/null || { TTY=0; YES=1; }
# Point stdin at the terminal: under `curl | bash` it is still the
# pipe, and an installer could read it as input.
if [ $TTY = 1 ]; then exec </dev/tty; else exec </dev/null; fi

if [ -t 1 ]; then
  B=$'\033[1m' G=$'\033[32m' R=$'\033[31m' Y=$'\033[33m' D=$'\033[2m' N=$'\033[0m'
else
  B= G= R= Y= D= N=
fi

say()  { printf '\n%s==> %s%s\n' "$B" "$*" "$N"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
no()   { printf '  %s✗%s %s\n' "$R" "$N" "$*"; }
old()  { printf '  %s~%s %s\n' "$Y" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*" >&2; }
has()  { command -v "$1" >/dev/null 2>&1; }
inlist() { case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }

# ask "question" y|n   -> status 0 for yes
ask() {
  local hint='[Y/n]' ans
  [ "$2" = n ] && hint='[y/N]'
  if [ $YES = 1 ]; then ans=$2; else
    printf '  %s %s ' "$1" "$hint"
    read -r ans || ans=
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

header() {  # header <os>
  printf '%sQuick_setup%s  %s %s' "$B" "$N" "$1" "$(uname -m)"
  [ -n "$LOCAL" ] && printf '  %s(local config: %s)%s' "$D" "$LOCAL" "$N"
  echo
}

DO=          # the steps to run, in the order they will run
PICK=        # package-manager tools to install
OPICK=       # tools to install with their own installer (Linux)
will() { has "$1" || inlist "$1" "$PICK" || inlist "$1" "$OPICK"; }   # present once we are done


# === Questions both systems ask ======================================

ask_common() {
  say "Rust"
  if has rustup; then ok "rustup"
  else
    no "rustup"
    ask "Install Rust (rustup, stable toolchain)?" y && DO="$DO rust"
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
}


# === Steps both systems run ==========================================

# rustup's own installer on both systems: it manages the toolchains
# either way, so a package manager would only add a second updater.
# PATH is already handled by .zshrc, so it leaves shell files alone.
do_rust() {
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs |
    sh -s -- -y --no-modify-path --profile default -c rust-analyzer -c rust-src
}

# The official installer updates itself in the background.
do_claude() { curl -fsSL https://claude.ai/install.sh | bash; }

# .zshrc is assembled from config/zsh/: the base, then one snippet per
# tool that is actually on this machine, so nothing refers to a
# command that is not there. A system script can define zshrc_head
# to put something in front (Homebrew's shellenv).
do_zshrc() {
  local t s
  get zshenv "$HOME/.zshenv" || return 1
  t=$(mktemp)
  {
    echo "# Generated by Quick_setup on $(date +%F). Re-running install.sh"
    echo "# regenerates it; keep your own additions in local.zsh."
    echo
    if type zshrc_head >/dev/null 2>&1; then zshrc_head; fi
    fetch zsh/base.zsh
    for s in micromamba nvim eza bat starship zoxide fzf yazi direnv atuin; do
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


# === Run the plan ====================================================

run_plan() {
  local s FAILED=
  if [ -z "$DO" ]; then say "Nothing to do"; return 0; fi
  say "Plan"
  for s in $DO; do
    case $s in
      tools)    echo "  - tools:$PICK" ;;
      official) echo "  - own installer:$OPICK" ;;
      *)        echo "  - $s" ;;
    esac
  done
  ask "Go ahead?" y || return 0

  for s in $DO; do
    say "$s"
    "do_$s" || { warn "$s failed"; FAILED="$FAILED $s"; }
  done

  say "Done"
  [ -d "$BACKUP" ] && echo "  backups: $BACKUP"
  if [ -n "$FAILED" ]; then
    no "failed:$FAILED  (re-run to retry)"
    return 1
  fi
  echo "  open a new terminal to start using it"
}
