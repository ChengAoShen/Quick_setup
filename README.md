# Quick_setup

**English** | [中文](README.zh-CN.md)

One interactive script that sets up zsh, a modern CLI toolchain
and their config files on macOS or Linux. On Linux everything
installs under `~`; sudo is only offered for the login shell and
the C compiler.

```sh
curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash
```

Nothing needs cloning: scripts and config files are downloaded from
this repo as the script goes. `… | bash -s -- -y` takes every
default without asking; `QS_REF=<branch>` fetches them from another
branch.

## How it works

1. **Detect**: shows the system and what is already installed.
2. **Ask**: every question comes up front, one item at a time.
3. **Install**: after one final confirmation, runs the steps in
   order and reports anything that failed.

`install.sh` only picks the system; each one has its own script,
and both share the helpers and every config file:

| File                | What it is                                              |
|---------------------|---------------------------------------------------------|
| `install.sh`        | entry point: runs `macos.sh` or `linux.sh`              |
| `scripts/macos.sh`  | macOS: Homebrew for everything it has                   |
| `scripts/linux.sh`  | Linux: conda-forge, uv's own installer, C compiler, login shell |
| `scripts/common.sh` | shared: helpers, Rust, Claude Code, config files, the plan |
| `config/`           | config files, the same on both systems                  |

From a checkout, `bash scripts/linux.sh` (or `macos.sh`) runs one
directly and uses the checkout's `config/`.

## Where everything comes from

**macOS: Homebrew wherever it can**, so `brew upgrade` updates it all.

| Item            | Source                                   |
|-----------------|------------------------------------------|
| CLI tools       | brew                                     |
| zsh plugins     | brew                                     |
| Rust            | official rustup: `~/.rustup`, `~/.cargo` |
| Claude Code     | official installer, updates itself       |

Rust and Claude Code are the exceptions: rustup manages the
toolchains whichever way it is installed, and brew's `rust`
formula would put a second cargo on `PATH`; Claude Code's own
installer updates in the background, brew's does not.

**Linux: conda-forge for the CLI tools.** micromamba needs no root,
has the same recent versions on every distro, where apt would lag
years behind and rename half the tools, and one command updates
them all. uv uses its own installer instead: `uv self update`
keeps it current, which conda-forge's package does not.

| Item            | Source                                   |
|-----------------|------------------------------------------|
| CLI tools       | conda-forge env `tools`, never activated; its binaries are linked into `~/.local/bin` |
| uv              | official installer: `~/.local/bin/uv`    |
| Package manager | micromamba, a single binary in `~/.local/bin` |
| zsh plugins     | git clone to `~/.local/share/zsh/plugins` |
| Rust            | official rustup: `~/.rustup`, `~/.cargo` |
| Claude Code     | official installer: `~/.local/bin/claude` |
| C compiler      | the system's: `build-essential` / `gcc` / `base-devel` with sudo; conda-forge gcc only without it |
| Login shell     | `sudo chsh` to the system zsh (installed with apt/dnf/pacman if missing) if the account can sudo, else `~/.bashrc` execs zsh |

Every installer is told to leave shell files alone; `.zshrc`
already has the PATH. A tool found only in `/usr/bin` or `/bin` is
still offered, since system copies there can be years old. A
conda-forge uv from an older version of this script is replaced by
the official one and removed from the env. The micromamba env root
is `~/.local/share/mamba`, or `~/micromamba` if that already exists.

A zsh under `~` (the conda-forge one) as the login shell is
offered a switch to the system zsh: SSH logins break the day that
copy does.

**One source per tool.** Each tool comes from exactly one of the
places above, never also from `cargo install` or a second
installer, so there is one copy on `PATH` and one way to update
it. cargo is there for Rust development, not for installing tools.

## Updating

| What                     | macOS          | Linux                                  |
|--------------------------|----------------|----------------------------------------|
| CLI tools                | `brew upgrade` | `micromamba update -n tools --all`     |
| uv                       | `brew upgrade` | `uv self update`                       |
| Rust                     | `rustup update` | `rustup update`                       |
| Claude Code              | automatic      | automatic                              |

## What can be installed

**Package managers**

| Name       | When                   |
|------------|------------------------|
| Homebrew   | macOS                  |
| micromamba | Linux                  |

**CLI tools**

| Tool      | What it is                    | Linux source | Shell setup added to `.zshrc`          |
|-----------|-------------------------------|--------------|----------------------------------------|
| zsh       | Z shell                       | conda-forge  | —                                      |
| git       | version control               | conda-forge  | aliases `g` `gs` `gd` `gl`             |
| starship  | prompt                        | conda-forge  | prompt init, `starship.toml`           |
| zoxide    | smarter `cd`                  | conda-forge  | replaces `cd`                          |
| fzf       | fuzzy finder                  | conda-forge  | Ctrl-T / Alt-C / Ctrl-R                |
| eza       | modern `ls`                   | conda-forge  | `ls` `ll` `la` `lt` `lta`              |
| bat       | `cat` with highlighting       | conda-forge  | `c`                                    |
| fd        | modern `find`                 | conda-forge  | —                                      |
| ripgrep   | fast grep (`rg`)              | conda-forge  | —                                      |
| jq        | JSON processor                | conda-forge  | —                                      |
| delta     | git diff pager                | conda-forge  | —                                      |
| neovim    | editor                        | conda-forge  | `EDITOR=nvim`, `vi`                    |
| tmux      | terminal multiplexer          | conda-forge  | `tmux.conf`                            |
| gh        | GitHub CLI                    | conda-forge  | —                                      |
| lazygit   | git TUI                       | conda-forge  | —                                      |
| btop      | system monitor                | conda-forge  | —                                      |
| atuin     | searchable shell history      | conda-forge  | takes over Ctrl-R                      |
| direnv    | per-directory environment     | conda-forge  | hook                                   |
| just      | command runner                | conda-forge  | —                                      |
| uv        | Python package manager        | official     | —                                      |
| fastfetch | system info greeting          | conda-forge  | greeting on start, `fastfetch/` config |
| yazi      | terminal file manager         | conda-forge  | `y` (cd to where you quit)             |
| node      | JavaScript runtime and npm    | conda-forge  | —                                      |
| tree-sitter | parser CLI for Neovim       | conda-forge  | —                                      |
| cc        | C compiler, Linux only        | system (sudo), else conda-forge | —                     |
| unzip     | zip extractor, Linux only     | conda-forge  | —                                      |

On macOS every one of them comes from brew.

**Others**

| Item                    | What it does                                           |
|-------------------------|--------------------------------------------------------|
| zsh-autosuggestions     | suggests commands from history                         |
| zsh-syntax-highlighting | colors commands as you type                            |
| Rust                    | rustup + stable toolchain, rust-analyzer, rust-src     |
| Claude Code             | Anthropic's CLI (off by default), plus `settings.json` |
| Neovim config           | clones [ChengAoShen/nvim](https://github.com/ChengAoShen/nvim) to `~/.config/nvim` |
| Login shell             | Linux only: makes the system zsh the default shell     |

## Config files

All of them are in `config/`, shared by both systems, and are
downloaded as the script runs.

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
4. `zsh/end.zsh`: `local.zsh`, then the two plugins (brew's copy,
   else the git clone)
5. `zsh/fastfetch.zsh`, if fastfetch is installed

So nothing in it refers to a command that is not there. Install
something later, re-run the script, and its snippet appears.

### local.zsh

`~/.config/zsh/local.zsh` (mode 600) is for API keys and anything
that belongs to one machine only: toolchains like `CUDA_HOME` or
`JAVA_HOME`, cache directories on a data disk, cluster-specific
functions. The script creates it once and never touches it again;
an existing `secrets.zsh` from an older setup is renamed to it.

Every file that gets replaced is moved to
`~/.local/state/quick_setup/backup-<time>/` first.

## Keeping machines in sync

Change files in `config/` or `scripts/`, push, then on each
machine:

```sh
curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash -s -- -y
```

Unchanged files are skipped; changed ones are backed up and
replaced. GitHub's raw URLs are cached for a few minutes, so wait a
little after pushing, or a machine may still get the old script.

## Adding a tool

- **macOS**: a line in `TOOLS` in `scripts/macos.sh` (command, brew
  package, description).
- **Linux**: a line in `TOOLS` in `scripts/linux.sh` (command,
  conda package, description). For one that should use its own
  installer instead, like uv: a line in `OFFICIAL` and an
  `inst_<command>` function that installs into `$BIN` without
  touching shell files.

If it needs shell setup, add `config/zsh/<command>.zsh` and put the
command in the snippet list in `do_zshrc` (`scripts/common.sh`).
