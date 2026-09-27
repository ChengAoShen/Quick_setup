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

| 步骤       | macOS    | Linux                                   |
|------------|----------|-----------------------------------------|
| 包管理器   | Homebrew | micromamba，装在 `~/.local/bin`         |
| 命令行工具 | brew     | conda-forge 环境，链接到 `~/.local/bin` |
| zsh 插件   | git clone 到 `~/.local/share/zsh/plugins` | 同左   |
| 默认 shell | 已是 zsh | 能用 sudo 就 `sudo chsh`，否则在 `~/.bashrc` 中 exec zsh |

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

**其他**

| 项目                    | 说明                                                  |
|-------------------------|-------------------------------------------------------|
| zsh-autosuggestions     | 根据历史记录提示命令                                  |
| zsh-syntax-highlighting | 输入时高亮命令                                        |
| Claude Code             | Anthropic 的命令行工具（默认不装），附带 `settings.json` |
| Neovim 配置             | 将 [ChengAoShen/nvim](https://github.com/ChengAoShen/nvim) clone 到 `~/.config/nvim` |
| 默认 shell              | 仅 Linux：将 zsh 设为默认 shell                       |

## 配置文件

```
config/
  zshenv                 -> ~/.zshenv（设置 ZDOTDIR）
  zsh/*.zsh              -> 拼装成 ~/.config/zsh/.zshrc
  starship.toml          -> ~/.config/starship.toml
  tmux.conf              -> ~/.config/tmux/tmux.conf
  fastfetch/             -> ~/.config/fastfetch/
  claude-settings.json   -> ~/.claude/settings.json
```

`.zshrc` 是**自动生成**的：先是 `zsh/base.zsh`（PATH、历史、
补全），然后为每个实际装上的工具追加对应片段，最后是
`zsh/end.zsh`（插件）。之后再装了新工具，重新运行脚本即可加上
它的配置。

个人配置和 API key 请放在 `~/.config/zsh/local.zsh`（权限 600）。
脚本只在第一次创建它，之后不会再改动。

所有被替换的文件都会先移动到
`~/.local/state/quick_setup/backup-<时间>/` 备份。

## 添加新工具

在 `install.sh` 的 `TOOLS` 中加一行（命令名、brew 包名、conda
包名、说明）。如果需要 shell 配置，添加 `config/zsh/<命令名>.zsh`，
并把命令名加入 `do_zshrc` 里的片段列表。
