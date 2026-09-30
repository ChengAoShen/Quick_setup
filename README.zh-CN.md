# Quick_setup

[English](README.md) | **中文**

一个交互式脚本，在 macOS 或 Linux 上配置好 zsh、一套现代命令行
工具以及它们的配置文件。Linux 上所有东西都装在 `~` 下，sudo 只在
设置默认 shell 和安装 C 编译器时可选使用。

```sh
curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash
```

无需 clone 仓库，脚本和配置文件在运行时从本仓库下载。`… | bash -s -- -y`
表示全部使用默认选项、不再询问；`QS_REF=<分支>` 可以从其他分支拉取。

## 工作流程

1. **检测**：显示系统信息和已安装的内容。
2. **询问**：所有问题在开头逐项问完。
3. **安装**：最后确认一次后按顺序执行，结束时汇报失败的步骤。

`install.sh` 只负责判断系统，两个系统各有一套脚本，共用辅助函数和
全部配置文件：

| 文件                | 作用                                                  |
|---------------------|-------------------------------------------------------|
| `install.sh`        | 入口：运行 `macos.sh` 或 `linux.sh`                   |
| `scripts/macos.sh`  | macOS：能用 Homebrew 的都用 Homebrew                  |
| `scripts/linux.sh`  | Linux：conda-forge、uv 官方安装、C 编译器、默认 shell |
| `scripts/common.sh` | 共用：辅助函数、Rust、Claude Code、配置文件、执行计划  |
| `config/`           | 配置文件，两个系统共用                                |

在 clone 下来的仓库里，也可以直接运行 `bash scripts/linux.sh`（或
`macos.sh`），这时用的是仓库里的 `config/`。

## 各组件从哪里安装

**macOS：能用 Homebrew 的都用 Homebrew**，`brew upgrade` 一条命令全部升级。

| 项目        | 来源                                   |
|-------------|----------------------------------------|
| 命令行工具  | brew                                   |
| zsh 插件    | brew                                   |
| Rust        | 官方 rustup：`~/.rustup`、`~/.cargo`   |
| Claude Code | 官方安装脚本，自动更新                 |

Rust 和 Claude Code 是例外：不管怎么装，工具链都由 rustup 管理，而
brew 的 `rust` 包会在 PATH 上多放一份 cargo；Claude Code 官方安装的
版本会在后台自动更新，brew 装的不会。

**Linux：命令行工具来自 conda-forge。** micromamba 不需要 root，在
所有发行版上版本一致且较新（apt 的版本往往落后好几年，包名也常常
不同），一条命令就能全部升级。uv 例外，用官方安装脚本：`uv self update`
能让它保持最新，conda-forge 的包更新较慢。

| 项目        | 来源                                   |
|-------------|----------------------------------------|
| 命令行工具  | conda-forge 的 `tools` 环境（不激活），命令链接到 `~/.local/bin` |
| uv          | 官方安装脚本：`~/.local/bin/uv`        |
| 包管理器    | micromamba，单个二进制文件，放在 `~/.local/bin` |
| zsh 插件    | git clone 到 `~/.local/share/zsh/plugins` |
| Rust        | 官方 rustup：`~/.rustup`、`~/.cargo`   |
| Claude Code | 官方安装脚本：`~/.local/bin/claude`    |
| C 编译器    | 系统自带：有 sudo 时装 `build-essential` / `gcc` / `base-devel`；没有 sudo 才用 conda-forge 的 gcc |
| 默认 shell  | 账号能用 sudo 就 `sudo chsh` 到系统 zsh（没有则用 apt/dnf/pacman 安装），否则在 `~/.bashrc` 中 exec zsh |

所有安装脚本都不会改 shell 配置文件，PATH 已经在 `.zshrc` 里。只在 `/usr/bin` 或 `/bin` 里有的工具也会列出来供安装，因为系统
自带的版本可能很旧；zsh 除外，默认 shell 用的正该是系统那份。
旧版本脚本用 conda-forge 装的 uv 会被换成官方版本，并从环境中删除。micromamba 的环境根目录是 `~/.local/share/mamba`；
如果已有 `~/micromamba`，则沿用它。

如果默认 shell 是 `~` 下的 zsh（conda-forge 那份），会提示换成系统
zsh，否则那份一坏，SSH 就登不进去。

**一个工具只从一个地方装。** 每个工具只来自上面其中一处，不再同时
用 `cargo install` 或其他安装方式，这样 PATH 上只有一份、升级也只有
一种方式。cargo 用于 Rust 开发，不用来装工具。

## 升级

| 内容                     | macOS          | Linux                                  |
|--------------------------|----------------|----------------------------------------|
| 命令行工具               | `brew upgrade` | `micromamba update -n tools --all`     |
| uv                       | `brew upgrade` | `uv self update`                       |
| Rust                     | `rustup update` | `rustup update`                       |
| Claude Code              | 自动           | 自动                                   |

## 可安装的内容

**包管理器**

| 名称       | 适用场景              |
|------------|-----------------------|
| Homebrew   | macOS                 |
| micromamba | Linux                 |

**命令行工具**

| 工具      | 说明                  | Linux 来源  | 加入 `.zshrc` 的配置                 |
|-----------|-----------------------|-------------|--------------------------------------|
| zsh       | Z shell               | conda-forge | —                                    |
| git       | 版本控制              | conda-forge | 别名 `g` `gs` `gd` `gl`              |
| starship  | 命令行提示符          | conda-forge | 提示符初始化、`starship.toml`        |
| zoxide    | 更智能的 `cd`         | conda-forge | 替换 `cd`                            |
| fzf       | 模糊查找              | conda-forge | Ctrl-T / Alt-C / Ctrl-R              |
| eza       | 现代化的 `ls`         | conda-forge | `ls` `ll` `la` `lt` `lta`            |
| bat       | 带语法高亮的 `cat`    | conda-forge | `c`                                  |
| fd        | 现代化的 `find`       | conda-forge | —                                    |
| ripgrep   | 快速 grep（`rg`）     | conda-forge | —                                    |
| jq        | JSON 处理工具         | conda-forge | —                                    |
| delta     | git diff 美化         | conda-forge | —                                    |
| neovim    | 编辑器                | conda-forge | `EDITOR=nvim`、`vi`                  |
| tmux      | 终端复用              | conda-forge | `tmux.conf`                          |
| gh        | GitHub 命令行         | conda-forge | —                                    |
| lazygit   | git 终端界面          | conda-forge | —                                    |
| btop      | 系统监控              | conda-forge | —                                    |
| atuin     | 可搜索的命令历史      | conda-forge | 接管 Ctrl-R                          |
| direnv    | 按目录加载环境变量    | conda-forge | hook                                 |
| just      | 命令运行器            | conda-forge | —                                    |
| uv        | Python 包管理         | 官方        | —                                    |
| fastfetch | 系统信息欢迎页        | conda-forge | 启动时显示、`fastfetch/` 配置        |
| yazi      | 终端文件管理器        | conda-forge | `y`（退出时 cd 到所在目录）          |
| node      | JavaScript 运行时和 npm | conda-forge | —                                  |
| tree-sitter | Neovim 用的解析器命令行 | conda-forge | —                                |
| cc        | C 编译器，仅 Linux    | 系统（sudo），否则 conda-forge | —                 |
| unzip     | zip 解压，仅 Linux    | conda-forge | —                                    |

macOS 上全部来自 brew。

**其他**

| 项目                    | 说明                                                  |
|-------------------------|-------------------------------------------------------|
| zsh-autosuggestions     | 根据历史记录提示命令                                  |
| zsh-syntax-highlighting | 输入时高亮命令                                        |
| Rust                    | rustup + stable 工具链、rust-analyzer、rust-src       |
| Claude Code             | Anthropic 的命令行工具（默认不装），附带 `settings.json` |
| Neovim 配置             | 将 [ChengAoShen/nvim](https://github.com/ChengAoShen/nvim) clone 到 `~/.config/nvim` |
| 默认 shell              | 仅 Linux：将系统 zsh 设为默认 shell                   |

## 配置文件

全部在 `config/` 目录下，两个系统共用，脚本运行时下载。

| 仓库中的文件           | 安装到                          | 内容 |
|------------------------|---------------------------------|------|
| `zshenv`               | `~/.zshenv`                     | 只设置 `ZDOTDIR=~/.config/zsh` |
| `zsh/*.zsh`            | `~/.config/zsh/.zshrc`          | 自动生成，见下 |
| `starship.toml`        | `~/.config/starship.toml`       | 分段式提示符：系统、目录、git、语言版本、conda 环境、时间 |
| `tmux.conf`            | `~/.config/tmux/tmux.conf`      | `hjkl` 切换窗格、`\|` / `-` 分屏、鼠标、真彩色、passthrough；状态栏只在 SSH 时显示 |
| `fastfetch/`           | `~/.config/fastfetch/`          | 欢迎页布局和图片 |
| `claude-settings.json` | `~/.claude/settings.json`       | Claude Code：禁止读取 `.env`、私钥和 `~/.ssh`；Concise 输出；开启思考 |

`.zshrc` 是**自动生成**的，顺序如下：

1. `brew shellenv`（仅 macOS）
2. `zsh/base.zsh`：PATH（`~/.local/bin`、`~/.cargo/bin`）、历史、
   选项、补全、`..` 和 git 别名
3. 每个实际装上的工具一段：`micromamba`、`nvim`、`eza`、`bat`、
   `starship`、`zoxide`、`fzf`、`yazi`、`direnv`、`atuin`
4. `zsh/end.zsh`：加载 `local.zsh`，然后是两个插件（优先用 brew
   装的，否则用 git clone 的）
5. `zsh/fastfetch.zsh`（装了 fastfetch 时）

所以里面不会引用没装的命令。之后再装了新工具，重新运行脚本即可
加上它的配置。

### local.zsh

`~/.config/zsh/local.zsh`（权限 600）用来放 API key 和只属于这台
机器的设置，例如 `CUDA_HOME`、`JAVA_HOME` 这类工具链、数据盘上的
缓存目录、集群专用的函数。脚本只在第一次创建它，之后不会再改动；
旧版本留下的 `secrets.zsh` 会被自动改名为它。

所有被替换的文件都会先移动到
`~/.local/state/quick_setup/backup-<时间>/` 备份。

## 多台机器保持同步

修改 `config/` 或 `scripts/` 并推送后，在每台机器上运行：

```sh
curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash -s -- -y
```

没有变化的文件会跳过，有变化的会先备份再替换。GitHub 的 raw 地址
有几分钟缓存，推送后稍等一会儿再运行，否则可能拿到旧版脚本。

## 添加新工具

- **macOS**：在 `scripts/macos.sh` 的 `TOOLS` 中加一行（命令名、brew
  包名、说明）。
- **Linux**：在 `scripts/linux.sh` 的 `TOOLS` 中加一行（命令名、conda
  包名、说明）。如果像 uv 一样要用官方安装脚本，就在 `OFFICIAL` 中加
  一行，再写一个 `inst_<命令名>` 函数，装到 `$BIN`，不改 shell 配置文件。

如果需要 shell 配置，添加 `config/zsh/<命令名>.zsh`，并把命令名加入
`do_zshrc`（`scripts/common.sh`）里的片段列表。
