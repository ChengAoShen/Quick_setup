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

Steps run in this order: package manager, CLI tools, zsh plugins,
Rust, Claude Code, config files, Neovim config, login shell.

## Where everything comes from

| Item            | macOS                   | Linux                                        |
|-----------------|-------------------------|----------------------------------------------|
| Package manager | Homebrew                | micromamba, a single binary in `~/.local/bin` |
| CLI tools       | brew                    | conda-forge env `tools`, never activated; its binaries are linked into `~/.local/bin` |
| zsh plugins     | git clone to `~/.local/share/zsh/plugins` | same                       |
| Rust            | official rustup: `~/.rustup`, `~/.cargo` | same                          |
| Claude Code     | official installer: `~/.local/bin/claude` | same                         |
| Login shell     | already zsh, left alone | `sudo chsh` if the account can sudo, else `~/.bashrc` execs zsh |

On Linux nothing needs root. A tool found only in `/usr/bin` or
`/bin` is still offered, since system copies there can be years
old. The micromamba env root is `~/.local/share/mamba`, or
`~/micromamba` if that already exists.

**One source per tool.** Every CLI tool comes from brew or
conda-forge, never also from `cargo install` or a second
installer, so there is one copy on `PATH` and one way to update
it. cargo is there for Rust development, not for installing tools.

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

All of them are in `config/` and are downloaded as the script runs.

| In the repo            | Installed to                     | What it holds |
|------------------------|----------------------------------|---------------|
| `zshenv`               | `~/.zshenv`                      | only `ZDOTDIR=~/.config/zsh` |
| `zsh/*.zsh`            | `~/.config/zsh/.zshrc`           | generated, see below |
| `starship.toml`        | `~/.config/starship.toml`        | powerline prompt: OS, directory, git, language versions, conda env, time |
| `tmux.conf`            | `~/.config/tmux/tmux.conf`       | `hjkl` pane moves, `\|` / `-` splits, mouse, true color, passthrough; status bar only over SSH |
| `fastfetch/`           | `~/.config/fastfetch/`           | greeting layout and logo |
| `claude-settings.json` | `~/.claude/settings.json`        | Claude Code: no reading `.env`, keys or `~/.ssh`; Concise output; thinking on |

`.zshrc` is **generated**, in this order:

1. `brew shellenv` (macOS only)
2. `zsh/base.zsh`: PATH (`~/.local/bin`, `~/.cargo/bin`), history,
   options, completion, `..` and git aliases
3. one snippet per tool that is actually installed: `micromamba`,
   `nvim`, `eza`, `bat`, `starship`, `zoxide`, `fzf`, `yazi`,
   `direnv`, `atuin`
4. `zsh/end.zsh`: `local.zsh`, then the two plugins
5. `zsh/fastfetch.zsh`, if fastfetch is installed

So nothing in it refers to a command that is not there. Install
something later, re-run the script, and its snippet appears.

### local.zsh

`~/.config/zsh/local.zsh` (mode 600) is for API keys and anything
that belongs to one machine only: toolchains like `JAVA_HOME`,
cache directories on a data disk, cluster-specific functions. The
script creates it once and never touches it again; an existing
`secrets.zsh` from an older setup is renamed to it.

Every file that gets replaced is moved to
`~/.local/state/quick_setup/backup-<time>/` first.

## Keeping machines in sync

Change files in `config/` (or `install.sh`), push, then on each
machine:

```sh
curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash -s -- -y
```

Unchanged files are skipped; changed ones are backed up and
replaced. GitHub's raw URLs are cached for a few minutes, so wait a
little after pushing, or a machine may still get the old script.

## Adding a tool

Add a line to `TOOLS` in `install.sh` (command, brew package,
conda package, description). If it needs shell setup, add
`config/zsh/<command>.zsh` and put the command in the snippet list
in `do_zshrc`.
