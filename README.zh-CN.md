# Quick_setup

[English](README.md) | **中文**

一个交互式脚本，在 macOS 或 Linux 上配置好 zsh、一套现代命令行
工具以及它们的配置文件。Linux 上所有东西都装在 `~` 下，sudo 只在
切换默认 shell 时可选使用。

```sh
curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash
```

无需 clone 仓库，配置文件在运行时从本仓库下载。`… | bash -s -- -y`
表示全部使用默认选项、不再询问；`QS_REF=<分支>` 可以从其他分支拉取配置。

## 工作流程

1. **检测**：显示系统信息和已安装的内容。
2. **询问**：所有问题在开头逐项问完。
3. **安装**：最后确认一次后按顺序执行，结束时汇报失败的步骤。

执行顺序：包管理器、命令行工具、zsh 插件、Rust、Claude Code、
配置文件、Neovim 配置、默认 shell。

## 各组件从哪里安装

| 项目       | macOS    | Linux                                   |
|------------|----------|-----------------------------------------|
| 包管理器   | Homebrew | micromamba，单个二进制文件，放在 `~/.local/bin` |
| 命令行工具 | brew     | conda-forge 的 `tools` 环境（不激活），命令链接到 `~/.local/bin` |
| zsh 插件   | git clone 到 `~/.local/share/zsh/plugins` | 同左   |
| Rust       | 官方 rustup：`~/.rustup`、`~/.cargo` | 同左         |
| Claude Code | 官方安装脚本：`~/.local/bin/claude` | 同左          |
| 默认 shell | 系统默认就是 zsh，不做改动 | 账号能用 sudo 就 `sudo chsh`，否则在 `~/.bashrc` 中 exec zsh |

Linux 上全程不需要 root。只在 `/usr/bin` 或 `/bin` 里有的工具也会
列出来供安装，因为系统自带的版本可能很旧。micromamba 的环境根目录
是 `~/.local/share/mamba`；如果已有 `~/micromamba`，则沿用它。

**一个工具只从一个地方装。** 所有命令行工具都来自 brew 或
conda-forge，不再同时用 `cargo install` 或其他安装方式，这样 PATH
上只有一份、升级也只有一种方式。cargo 用于 Rust 开发，不用来装工具。

## 可安装的内容

**包管理器**

| 名称       | 适用场景              |
|------------|-----------------------|
| Homebrew   | macOS                 |
| micromamba | Linux                 |

**命令行工具**

| 工具      | 说明                  | 加入 `.zshrc` 的配置                 |
|-----------|-----------------------|--------------------------------------|
| zsh       | Z shell               | —                                    |
| git       | 版本控制              | 别名 `g` `gs` `gd` `gl`              |
| starship  | 命令行提示符          | 提示符初始化、`starship.toml`        |
| zoxide    | 更智能的 `cd`         | 替换 `cd`                            |
| fzf       | 模糊查找              | Ctrl-T / Alt-C / Ctrl-R              |
| eza       | 现代化的 `ls`         | `ls` `ll` `la` `lt` `lta`            |
| bat       | 带语法高亮的 `cat`    | `c`                                  |
| fd        | 现代化的 `find`       | —                                    |
| ripgrep   | 快速 grep（`rg`）     | —                                    |
| delta     | git diff 美化         | —                                    |
| neovim    | 编辑器                | `EDITOR=nvim`、`vi`                  |
| tmux      | 终端复用              | `tmux.conf`                          |
| gh        | GitHub 命令行         | —                                    |
| lazygit   | git 终端界面          | —                                    |
| btop      | 系统监视器            | —                                    |
| atuin     | 可搜索的命令历史      | 接管 Ctrl-R                          |
| direnv    | 按目录加载环境变量    | hook                                 |
| just      | 命令运行器            | —                                    |
| uv        | Python 包管理         | —                                    |
| fastfetch | 系统信息欢迎页        | 启动时显示、`fastfetch/` 配置        |
| yazi      | 终端文件管理器        | `y`（退出后 cd 到所在目录）          |

**其他**

| 项目                    | 说明                                                  |
|-------------------------|-------------------------------------------------------|
| zsh-autosuggestions     | 根据历史记录提示命令                                  |
| zsh-syntax-highlighting | 输入时高亮命令                                        |
| Rust                    | rustup + stable 工具链、rust-analyzer、rust-src       |
| Claude Code             | Anthropic 的命令行工具（默认不装），附带 `settings.json` |
| Neovim 配置             | 将 [ChengAoShen/nvim](https://github.com/ChengAoShen/nvim) clone 到 `~/.config/nvim` |
| 默认 shell              | 仅 Linux：将 zsh 设为默认 shell                       |

## 配置文件

全部在 `config/` 目录下，脚本运行时下载。

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
4. `zsh/end.zsh`：加载 `local.zsh`，然后是两个插件
5. `zsh/fastfetch.zsh`（装了 fastfetch 时）

所以里面不会引用没装的命令。之后再装了新工具，重新运行脚本即可
加上它的配置。

### local.zsh

`~/.config/zsh/local.zsh`（权限 600）用来放 API key 和只属于这台
机器的设置，例如 `JAVA_HOME` 这类工具链、数据盘上的缓存目录、集群
专用的函数。脚本只在第一次创建它，之后不会再改动；旧版本留下的
`secrets.zsh` 会被自动改名为它。

所有被替换的文件都会先移动到
`~/.local/state/quick_setup/backup-<时间>/` 备份。

## 多台机器保持同步

修改 `config/`（或 `install.sh`）并推送后，在每台机器上运行：

```sh
curl -fsSL https://raw.githubusercontent.com/ChengAoShen/Quick_setup/main/install.sh | bash -s -- -y
```

没有变化的文件会跳过，有变化的会先备份再替换。GitHub 的 raw 地址
有几分钟缓存，推送后稍等一会儿再运行，否则可能拿到旧版脚本。

## 添加新工具

在 `install.sh` 的 `TOOLS` 中加一行（命令名、brew 包名、conda
包名、说明）。如果需要 shell 配置，添加 `config/zsh/<命令名>.zsh`，
并把命令名加入 `do_zshrc` 里的片段列表。
