# Quick_setup

**English** | [中文](README.zh-CN.md)

One interactive script that sets up zsh, a modern CLI toolchain
and their config files on macOS or Linux. On Linux everything
installs under `~`; sudo is only offered for changing the login shell.

```sh
curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash
```

Nothing needs cloning: config files are downloaded from this repo
as the script goes. `… | bash -s -- -y` takes every default without asking;
`QS_REF=<branch>` fetches configs from another branch.

## How it works

1. **Detect**: shows the system and what is already installed.
2. **Ask**: every question comes up front, one item at a time.
3. **Install**: after one final confirmation, runs the steps in
   order and reports anything that failed.

| Step            | macOS                   | Linux                                        |
|-----------------|-------------------------|----------------------------------------------|
| Package manager | Homebrew                | micromamba in `~/.local/bin`                 |
| CLI tools       | brew                    | conda-forge env, linked into `~/.local/bin`  |
| zsh plugins     | git clone to `~/.local/share/zsh/plugins` | same                       |
| Login shell     | already zsh             | `sudo chsh` if possible, else `~/.bashrc` execs zsh |

## What can be installed

**Package managers**

| Name       | When                   |
|------------|------------------------|
| Homebrew   | macOS                  |
| micromamba | Linux                  |

**CLI tools**

| Tool      | What it is                    | Shell setup added to `.zshrc`          |
|-----------|-------------------------------|----------------------------------------|
| zsh       | Z shell                       | —                                      |
| git       | version control               | aliases `g` `gs` `gd` `gl`             |
| starship  | prompt                        | prompt init, `starship.toml`           |
| zoxide    | smarter `cd`                  | replaces `cd`                          |
| fzf       | fuzzy finder                  | Ctrl-T / Alt-C / Ctrl-R                |
| eza       | modern `ls`                   | `ls` `ll` `la` `lt` `lta`              |
| bat       | `cat` with highlighting       | `c`                                    |
| fd        | modern `find`                 | —                                      |
| ripgrep   | fast grep (`rg`)              | —                                      |
| delta     | git diff pager                | —                                      |
| neovim    | editor                        | `EDITOR=nvim`, `vi`                    |
| tmux      | terminal multiplexer          | `tmux.conf`                            |
| gh        | GitHub CLI                    | —                                      |
| lazygit   | git TUI                       | —                                      |
| btop      | system monitor                | —                                      |
| atuin     | searchable shell history      | takes over Ctrl-R                      |
| direnv    | per-directory environment     | hook                                   |
| just      | command runner                | —                                      |
| uv        | Python package manager        | —                                      |
| fastfetch | system info greeting          | greeting on start, `fastfetch/` config |
| yazi      | terminal file manager         | `y` (cd to where you quit)             |

**Others**

| Item                    | What it does                                           |
|-------------------------|--------------------------------------------------------|
| zsh-autosuggestions     | suggests commands from history                         |
| zsh-syntax-highlighting | colors commands as you type                            |
| Rust                    | rustup + stable toolchain, rust-analyzer, rust-src     |
| Claude Code             | Anthropic's CLI (off by default), plus `settings.json` |
| Neovim config           | clones [ChengAoShen/nvim](https://github.com/ChengAoShen/nvim) to `~/.config/nvim` |
| Login shell             | Linux only: makes zsh the default shell                |

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

`.zshrc` is **generated**: `zsh/base.zsh` (PATH, history,
completion), then one snippet for each tool actually installed,
then `zsh/end.zsh` (plugins). Install something later, re-run the
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
