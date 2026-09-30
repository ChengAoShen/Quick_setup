#!/usr/bin/env bash
#
# Quick_setup for macOS. install.sh runs this; from a checkout it
# also runs on its own:
#
#   bash scripts/macos.sh [-y]
#
# Everything Homebrew has comes from Homebrew, so `brew upgrade`
# updates it all. Only Rust (rustup manages its own toolchains) and
# Claude Code (updates itself) use their official installers.

set -uo pipefail   # no -e: one failed step should not stop the rest
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

find_brew() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then BREW=$b; eval "$("$b" shellenv)"; return 0; fi
  done
  return 1
}

export PATH=$BIN:$HOME/.cargo/bin:$PATH
BREW=
find_brew

# cmd  brew-package  description
TOOLS='
zsh        zsh             Z shell
git        git             version control
starship   starship        prompt
zoxide     zoxide          smarter cd
fzf        fzf             fuzzy finder
eza        eza             modern ls
bat        bat             cat with highlighting
fd         fd              modern find
rg         ripgrep         fast grep
jq         jq              JSON processor
delta      git-delta       git diff pager
nvim       neovim          editor
tmux       tmux            terminal multiplexer
gh         gh              GitHub CLI
lazygit    lazygit         git TUI
btop       btop            system monitor
atuin      atuin           searchable shell history
direnv     direnv          per-directory env
just       just            command runner
uv         uv              Python packages
fastfetch  fastfetch       system info greeting
yazi       yazi            terminal file manager
node       node            JavaScript runtime, npm
tree-sitter tree-sitter-cli parser CLI for Neovim
'
# Not commands, so checked by file instead.
PLUGINS='zsh-autosuggestions zsh-syntax-highlighting'

pkg_of() {  # pkg_of <cmd>
  echo "$TOOLS" | while read -r c p _; do [ "$c" = "$1" ] && echo "$p"; done
}


main() {
header macos

say "Package manager"
if [ -n "$BREW" ]; then ok "Homebrew ($BREW)"
else
  no "Homebrew"
  ask "Install Homebrew?" y && DO="$DO brew"
fi
CAN_PKG=$( { [ -n "$BREW" ] || inlist brew "$DO"; } && echo 1)

say "CLI tools"
local missing= c desc
while read -r c _ desc; do
  [ -n "$c" ] || continue
  if has "$c"; then ok "$c"
  else no "$c  $D$desc$N"; missing="$missing $c"
  fi
done <<EOF
$TOOLS
EOF
if [ -z "$missing" ]; then :
elif [ -z "$CAN_PKG" ]; then warn "no Homebrew, skipping tools"
elif ask "Install all of:$missing?" y; then PICK=$missing
else
  for c in $missing; do ask "  $c?" y && PICK="$PICK $c"; done
fi
[ -n "$PICK" ] && DO="$DO tools"

say "zsh plugins"
if [ -n "$BREW" ] && plugins_in_brew; then ok "autosuggestions, syntax-highlighting"
else
  no "autosuggestions, syntax-highlighting"
  [ -n "$CAN_PKG" ] && ask "Install them with brew?" y && DO="$DO plugins"
fi

ask_common
run_plan
}

plugins_in_brew() {
  local p pre; pre=$("$BREW" --prefix)
  for p in $PLUGINS; do [ -r "$pre/share/$p/$p.zsh" ] || return 1; done
}

do_brew() {
  sudo -v || return 1   # Homebrew's non-interactive mode needs sudo cached
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &&
    find_brew
}

do_tools() {
  local c pkgs=
  for c in $PICK; do pkgs="$pkgs $(pkg_of "$c")"; done
  [ -n "$pkgs" ] || return 0
  brew install $pkgs
}

do_plugins() { brew install $PLUGINS; }

# .zshrc starts with brew's PATH, MANPATH and completions: before
# compinit, and it sets HOMEBREW_PREFIX, where the plugins are.
zshrc_head() {
  [ -n "$BREW" ] || return 0
  printf '# Homebrew: PATH, MANPATH and completions. Before compinit.\n'
  printf 'eval "$(%s shellenv zsh)"\n\n' "$BREW"
}

main; exit $?
