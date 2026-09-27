# Quick_setup

One interactive script that sets up zsh, a modern CLI toolchain
and their config files on macOS or Linux, with or without sudo.

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh)
```

Nothing needs cloning: config files are downloaded from this repo
as the script goes. `-y` takes every default without asking;
`QS_REF=<branch>` fetches configs from another branch.

## What it does

1. **Looks** at the system and shows what is already there.
2. **Asks**, one item at a time, what to install or write.
3. **Does it** in order, then reports anything that failed.

| Step            | macOS    | Linux, sudo                | Linux, no sudo                |
|-----------------|----------|----------------------------|-------------------------------|
| Package manager | Homebrew | apt/dnf/pacman + Homebrew  | micromamba in `~/.local/bin`  |
| CLI tools       | brew     | brew                       | conda-forge env, linked into `~/.local/bin` |
| zsh plugins     | git clone to `~/.local/share/zsh/plugins` | same | same |
| Login shell     | `chsh`   | `chsh`                     | `~/.bashrc` execs zsh         |

Tools on offer: zsh, git, starship, zoxide, fzf, eza, bat, fd,
ripgrep, delta, neovim, tmux, gh, lazygit, btop, atuin, direnv,
just, uv, fastfetch, and optionally Claude Code.

## Config files

```
config/
  zshenv                 -> ~/.zshenv (sets ZDOTDIR)
  zsh/*.zsh              -> assembled into ~/.config/zsh/.zshrc
  starship.toml          -> ~/.config/starship.toml
  tmux.conf              -> ~/.config/tmux/tmux.conf
  fastfetch/             -> ~/.config/fastfetch/
  claude-settings.json   -> ~/.claude/settings.json
```

`.zshrc` is **generated**: `zsh/base.zsh`, then one snippet for
each tool actually installed (`zsh/eza.zsh`, `zsh/starship.zsh`,
...), then `zsh/end.zsh`. Install something later, re-run the
script, and its snippet appears.

Put your own additions and API keys in `~/.config/zsh/local.zsh`
(mode 600). The script creates it once and never touches it again.

Every file that gets replaced is moved to
`~/.local/state/quick_setup/backup-<time>/` first.

## Adding a tool

Add a line to `TOOLS` in `install.sh` (command, brew package,
conda package, description). If it needs shell setup, add
`config/zsh/<command>.zsh` and put the command in the snippet list
in `do_zshrc`.
