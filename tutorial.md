# 工具与环境命令手册

这一页是装进来的工具和环境提供的命令；`wtool` 命令本身见 [wtool.md](wtool.md)。
安装见 [install.md](install.md)。

每条命令写三块：功能、参数、运行结果。

## repo 相关命令

这些函数由 `tools/git-repo-sh-tools` 提供，zsh 和 bash 同名。

### cs

**功能**：跳到 repo 工作区根目录。

**参数**：无。

**运行结果**：

```text
$ cd tools/git-repo-sh-tools
$ cs
$ pwd
/home/you/self/wtool
```

![cs](img/cs.png)

### css

**功能**：打印 repo 工作区根目录，不跳转。

**参数**：无。

**运行结果**：

```text
$ css
/home/you/self/wtool
```

![css](img/css.png)

### ct

**功能**：跳到当前项目（最近的 `.git`）根目录。

**参数**：无。

**运行结果**：

```text
$ cd tools/git-repo-sh-tools/tests
$ ct
$ pwd
/home/you/self/wtool/tools/git-repo-sh-tools
```

![ct](img/ct.png)

### ctt

**功能**：打印当前项目根目录，不跳转。

**参数**：无。

**运行结果**：

```text
$ ctt
/home/you/self/wtool/tools/git-repo-sh-tools
```

![ctt](img/ctt.png)

### cnp

**功能**：打印当前项目在清单里的相对路径。

**参数**：无。传参数会报错。

**运行结果**：

```text
$ cnp
tools/git-repo-sh-tools
```

![cnp](img/cnp.png)

### cnn

**功能**：打印当前项目在清单里的仓库名。

**参数**：无。传参数会报错。

**运行结果**：

```text
$ cnn
allinkernel/wtool-repo.git
```

![cnn](img/cnn.png)

### cnb

**功能**：打印清单里给当前项目声明的分支。

**参数**：无。

**运行结果**：

```text
$ cnb
main
```

![cnb](img/cnb.png)

### cnr

**功能**：打印清单里给当前项目声明的 remote 名。

**参数**：无。

**运行结果**：

```text
$ cnr
github
```

![cnr](img/cnr.png)

### cm

**功能**：跳到 `.repo/manifests`。

**参数**：无。

**运行结果**：

```text
$ cm
$ pwd
/home/you/self/wtool/.repo/manifests
```

![cm](img/cm.png)

### cmm

**功能**：打印 `.repo/manifests` 路径。

**参数**：无。

**运行结果**：

```text
$ cmm
/home/you/self/wtool/.repo/manifests
```

![cmm](img/cmm.png)

### cdd

**功能**：跳转：项目名、路径、现存文件/目录、gerrit 提交编号、一串点。

**参数**：

| 参数 | 说明 |
|---|---|
| `TARGET` | 只收一个。项目名 / 清单路径 / 现存路径 / `-N` 或 `N`（gerrit 编号）/ `..`、`...`（往上跳点数减一层） |

**运行结果**：

```text
$ cdd terminal/tmux
$ pwd
/home/you/self/wtool/terminal/tmux
```

```text
$ cdd -1234                  # 跳到 change 1234 所属项目
$ cdd ...                    # 往上跳两层
```

成功时无输出。找不到时：

```text
$ cdd no-such-project
cdd: 清单里没有 'no-such-project' 这个项目名或路径
     看看都有什么：/home/you/self/wtool/tools/git-repo-sh-tools/my_repo.py list --root /home/you/self/wtool
```

![cdd](img/cdd.png)
![cdd 失败](img/cdd-fail.png)
![cdd -N](img/cdd-dash.png)
![cdd -N 失败](img/cdd-dash-fail.png)

### cdd_path

**功能**：打印项目名对应的绝对路径，不跳转。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目名\|路径>` | 一个 |

**运行结果**：

```text
$ cdd_path terminal/tmux
/home/you/self/wtool/terminal/tmux
```

![cdd_path](img/cdd-path.png)

### rs

**功能**：生成当前清单快照，然后 `repo sync` 到这份快照。

**参数**：无。

**运行结果**：直接执行下面两条，输出就是 `repo` 的输出。

```text
repo manifest -o /tmp/tmp.XXXXXX.xml
repo sync -c -j32 --force-sync --force-checkout -d -m /tmp/tmp.XXXXXX.xml
```

![rs](img/rs.png)

### rscur

**功能**：只同步当前目录所属的项目；不在项目根时同步该目录下的子项目。执行前询问。

**参数**：无。

**运行结果**：

```text
==>repo sync -c <项目>
total N repos in <相对路径>, execute it? ({ENTER/Y/y}/{N/n/*})
```

![rscur](img/rscur.png)

### wninja

**功能**：用当前项目的 `out/` 里的 ninja 文件跑 ninja。仅 zsh 可用。参数原样传给 ninja。

**参数**：

| 参数 | 说明 |
|---|---|
| `<ninja 参数>...` | 全部透传给 ninja |

**运行结果**：

```text
$ wninja
Error: No ninja build file found.
```

![wninja](img/wninja.png)

### gb

**功能**：打印当前项目可用的 push / pull / fetch 命令，以及 remote、branch。

**参数**：无。

**运行结果**：

```text
$ gb
git push github HEAD:refs/for/main
git push github HEAD:main
git pull github main --unshallow
git pull github main
git fetch github main --unshallow
git fetch github main
remote: github
branch: main
github	https://github.com/allinkernel/wtool-repo.git (fetch)
github	https://github.com/allinkernel/wtool-repo.git (push)
```

![gb](img/gb.png)

### gpun

**功能**：执行 `gb` 打印的 `git pull <remote> <branch> --unshallow`。

**参数**：

| 参数 | 说明 |
|---|---|
| 无 | 补全历史 |
| `-N` / `--depth=N` | 只拉 N 层，把 `--unshallow` 换成 `--depth=N` |

**运行结果**：

```text
$ gpun
gpun: 执行 git pull github main --unshallow
```

```text
$ gpun -30
gpun: 执行 git pull github main --depth=30
```

![gpun](img/gpun.png)

### gbb

**功能**：从 `gb` 的输出里挑直接 push 那条并执行。

**参数**：无。

**运行结果**：

```text
$ gbb
git push github HEAD:main
```

![gbb](img/gbb.png)

## gerrit 相关命令

服务器地址用环境变量或配置文件给：

```bash
export WTOOL_GERRIT_HOST=user@host:29418
```

```text
# <repo 根>/.gerrit/client.conf 或 ~/.wtool/gerrit.conf
host=gerrit.company.com
port=29418
user=yourname
sshkey=~/.ssh/id_rsa
```

### ggcp

**功能**：把 gerrit 上的提交抓回本地，切到对应项目，cherry-pick。

**参数**：

| 参数 | 说明 |
|---|---|
| `<编号>` | 一个或多个；逗号或空格分隔，如 `1234`、`1,2,3`、`1 2 3` |
| `<链接>` | `https://host/#/c/1234`、`https://host/c/proj/+/1234` |
| `<Change-Id>` | `I` 加 40 位十六进制；先查 gerrit，打表后逐个询问 |
| `1234/2` | 直接指定 patchset |
| `-p <n>` | 指定 patchset |
| `-y` / `--yes` | 全都打，不再问 |
| `-n` / `--no` | 全都跳过 |

**运行结果**：

```text
$ ggcp 1,2
1 个仓库 / 2 笔提交 / 成功 2 / 失败 0
项目名           项目路径  提交 id       patchset  结果说明
---------------  --------  ------------  --------  --------
platform/mylib   mylib     a1b2c3d4e5f6  1         成功
platform/mylib   mylib     b2c3d4e5f6a1  2         成功
```

同一 Change-Id 已在本地历史时，不抓、不打：

```text
此 Change-Id 已在本地历史（提交 a1b2c3d4e5f6，patchset 1）→ 先 ggrvt 1234 回退，再打 1234/2
```

![ggcp 成功](img/ggcp-ok.png)
![ggcp 失败](img/ggcp-fail.png)
![ggcp 同 Change-Id 被拦](img/ggcp-same-change.png)
![ggcp 多笔](img/ggcp-multi.png)

### ggrvt

**功能**：把本地历史里同 Change-Id 的提交 revert 掉。只改本地。

**参数**：

| 参数 | 说明 |
|---|---|
| `<编号>` | gerrit change 编号 |
| `<链接>` | gerrit 链接 |
| `<Change-Id>` | `I` 加 40 位十六进制 |

不接受 patchset：`ggrvt 1234/2` 报错。

**运行结果**：

```text
$ ggrvt 1234
已回退 a1b2c3d4e5f6（change 1234, patchset 2）→ 现在可以 ggcp 1234/2
```

![ggrvt 成功](img/ggrvt-ok.png)
![ggrvt 失败](img/ggrvt-fail.png)

### gchk

**功能**：查一个 change 有没有 +2、有没有 merged。

**参数**：

| 参数 | 说明 |
|---|---|
| `<change>` | 编号、链接或 Change-Id |

退出码：0 = 已 merged，1 = 还没，2 = 查不到。

**运行结果**：

```text
$ gchk 1234
change 1234  [NEW]
  project : platform/mylib
  branch  : main
  subject : lab: change one (ps1)
  patchset: 2  a1b2c3d4e5f6
  投票    : Code-Review +2 by alice
  链接    : https://gerrit.example.com/c/platform/mylib/+/1234
  => 已 +2（来自 alice），但还没 merged
```

![gchk](img/gchk.png)

### gq

**功能**：列出一个 change 的摘要。

**参数**：

| 参数 | 说明 |
|---|---|
| `<change>` | 编号、链接或 Change-Id |
| `-r` / `--raw` | 输出原始 JSON |

**运行结果**：

```text
$ gq 1234
1234	NEW	platform/mylib	lab: change one
```

![gq](img/gq.png)

### gpush

**功能**：把当前 HEAD 推到 `refs/for/<清单声明的分支>`。

**参数**：

| 参数 | 说明 |
|---|---|
| `[remote]` | 默认 `polygerrit` |
| `[额外参数]...` | 透传给 `git push` |

**运行结果**：

```text
$ gpush
gpush: git push polygerrit HEAD:refs/for/main
```

![gpush](img/gpush.png)

### ggco

**功能**：从远端抓一个分支 / tag / commit，然后切过去。

**参数**：

| 参数 | 说明 |
|---|---|
| `<分支\|tag\|commit>` | 一个，不能以 `-` 开头 |

工作树有本地改动时拒绝执行。

**运行结果**：

```text
$ ggco main
ggco: /home/you/self/wtool/tools/git-repo-sh-tools 现在在 main @ 1a2b3c4（来自 github main）
```

![ggco](img/ggco.png)

## shell 集成与别名

这些别名和函数由 `shell/shell-rc` 提供。

### 别名

**功能**：常用命令缩写。

**参数**：无。

| 别名 | 实际命令 |
|---|---|
| `gs` | `git status` |
| `gss` | `git status --short` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gll` | `git log` |
| `gl` | `git log` |
| `s` | `ls` |
| `sl` | `ls` |
| `lks` | `ls` |
| `kls` | `ls` |

![别名](img/aliases.png)

### cw

**功能**：跳到含 `.repo` 的工作区根。

**参数**：无。

**运行结果**：

```text
$ cw
$ pwd
/home/you/self/wtool
```

![cw](img/cw.png)

### gba

**功能**：`git branch -a`，有 `batcat` 时用 `batcat` 分页。

**参数**：无。

**运行结果**：

```text
$ gba
* ds_dev
  main
  remotes/github/ds_dev
  remotes/github/main
  remotes/m/wtool -> github/main
```

![gba](img/gba.png)

### pwd

**功能**：打印当前目录，同时记到 `/tmp/wsw-temp-pwd-id-<uid>`。

**参数**：无。

**运行结果**：

```text
$ cd /tmp
$ pwd
/tmp
```

![pwd](img/pwd.png)

### pdd

**功能**：回到 `pwd` 上次记下的目录。

**参数**：无。

**运行结果**：

```text
$ pdd
$ pwd
/tmp
```

![pdd](img/pdd.png)

### pss

**功能**：打印 `pwd` 上次记下的目录。

**参数**：无。

**运行结果**：

```text
$ pss
/tmp
```

![pss](img/pss.png)

### this_is_wsl

**功能**：判断是不是 WSL。WSL 上 rc=0。

**参数**：无。

**运行结果**：

```text
$ this_is_wsl; echo $?
0
```

![this_is_wsl](img/this-is-wsl.png)

### this_is_not_wsl

**功能**：判断是不是非 WSL。非 WSL 上 rc=0。

**参数**：无。

**运行结果**：

```text
$ this_is_not_wsl; echo $?
1
```

![this_is_not_wsl](img/this-is-not-wsl.png)

### win

**功能**：把当前目录或给定路径翻译成 mac / Windows / scp / WSL / Linux 可用的路径，打一张表。

**参数**：

| 参数 | 说明 |
|---|---|
| 无 | 用当前目录 |
| `<路径>` | 用给定路径 |

没有 `WIN_IP` 时对应行显示「请设置 WIN_IP」。

**运行结果**：

```text
$ win
usage  path
mac    请设置 WIN_IP
win    请设置 WIN_IP
scp    请设置 WIN_IP
wsl    \\wsl.localhost\mindul-ubuntu14\tmp
linux  请设置 WIN_IP
```

![win](img/win.png)

### start

**功能**：在 Windows 侧打开文件、目录或程序。仅 WSL。

**参数**：

| 参数 | 说明 |
|---|---|
| `<路径\|程序名>` | 路径会先解析软链；裸词原样交给 Windows |

**运行结果**：

```text
$ start /no/such/path
start: 路径不存在：/no/such/path
```

非 WSL：

```text
$ start .
only wsl support this
```

![start 失败](img/start-fail.png)

### proxy_on

**功能**：导出 `http_proxy` / `https_proxy` / `all_proxy` 及其大写变量，并补 `no_proxy`。

**参数**：

| 参数 | 说明 |
|---|---|
| `<IP>` | 不给就用 `$PROXY_IP`；非交互时必填 |
| `[端口]` | 不给就用 `$PROXY_PORT`，默认 7897 |

**运行结果**：

```text
$ proxy_on 127.0.0.1 7897
Proxy ON  http://127.0.0.1:7897  (all_proxy=socks5://127.0.0.1:7897)
          no_proxy=localhost,127.0.0.1,::1,.local
```

![proxy_on](img/proxy-on.png)

### proxy_off

**功能**：清除代理变量，恢复原来的 `no_proxy`。

**参数**：无。

**运行结果**：

```text
$ proxy_off
Proxy OFF（代理变量已清除；PROXY_IP/PROXY_PORT 留着，下次 proxy_on 不用再问）
```

![proxy_off](img/proxy-off.png)

### wrg

**功能**：按构建目标名搜索 `Android.bp`、`Android.mk` 和 Makefile。

**参数**：

| 参数 | 说明 |
|---|---|
| `<名字>` | 精确匹配目标名 |
| `-i` / `--ignore-case` | 去 `_` 后按子串模糊匹配 |
| `-e <名字>` | 多名字查询，可重复 |
| `-t bp\|mk\|make` | 只搜某类文件 |
| `-A/-B/-C <n>` | 上下文行数 |
| `-l` / `--files` | 只打印文件路径 |
| `-c` / `--count` | 打印每个文件的命中条数 |
| `-m <n>` | 全局最多输出 n 条 |
| `--color[=WHEN]` | `auto` / `always` / `never` |
| `-v` / `--version` | 版本和搜索后端 |

环境变量：`WRG_SEARCH=auto|rg|fd|find`、`WRG_COLOR=auto|always|never`、`NO_COLOR`。

**运行结果**：

```text
$ wrg -v
wrg 1.0（后端 rg）
```

![wrg -v](img/wrg.png)

### oh-my-zsh

**功能**：加载 oh-my-zsh，主题 `ys`，插件 `git`。

**参数**：无。

**运行结果**：交互式 zsh 里提示符为主题 `ys` 的样式。

```text
ZSH_THEME="ys"
plugins=(git)
source $ZSH/oh-my-zsh.sh
```

![oh-my-zsh 主题](img/oh-my-zsh.png)

### z

**功能**：zoxide 的跳目录函数。

**参数**：

| 参数 | 说明 |
|---|---|
| `<目录片段>` | 跳到匹配度最高的目录 |

**运行结果**：

```text
$ z wtool && pwd
/home/you/self/wtool
```

![z](img/z.png)

### zi

**功能**：zoxide 的交互式选择目录函数。

**参数**：

| 参数 | 说明 |
|---|---|
| `<目录片段>` | 可选，先按片段过滤 |

**运行结果**：

```text
$ zi
```

打开 fzf 选择目录，回车后跳过去。

![zi](img/zi.png)

### fzf-history-widget

**功能**：zsh 的 fzf 历史搜索 widget，绑在 `Ctrl-R`。

**参数**：无。

**运行结果**：

```text
$ bindkey '^R'
"^R" fzf-history-widget
```

![Ctrl-R / fzf-history-widget](img/fzf-history.png)
![Ctrl-R（bash）](img/ctrl-r-bash.png)

### fzf-file-widget

**功能**：fzf 的文件选择 widget，zsh 绑在 `Ctrl-T`，bash 也绑在 `Ctrl-T`。

**参数**：无。

**运行结果**：

```text
$ bindkey '^T'
"^T" fzf-file-widget
```

![Ctrl-T / fzf-file-widget](img/fzf-file.png)

### fzf-cd-widget

**功能**：fzf 的目录选择 widget，zsh 绑在 `Alt-C`（`^[c`）。

**参数**：无。

**运行结果**：

```text
$ bindkey '^[c'
"^[c" fzf-cd-widget
```

![Alt-C / fzf-cd-widget](img/fzf-cd.png)

### fzf-completion

**功能**：fzf 的补全 widget，zsh 绑在 `Tab`（`^I`）。

**参数**：无。

**运行结果**：

```text
$ bindkey '^I'
"^I" fzf-completion
```

![fzf-completion](img/fzf-completion.png)

### tmux-wtool

**功能**：用项目自己的 `tmux.conf` 启动 tmux。

**参数**：`tmux` 自己的参数原样传入。

**运行结果**：

```text
$ alias tmux-wtool
alias tmux-wtool='command tmux -f "$WTOOL_TMUX_DIR/tmux.conf"'
```

![tmux-wtool](img/tmux-wtool.png)

### 内部辅助函数

这些函数会被别的函数调用，一般不直接敲。

| 函数 | 用途 |
|---|---|
| `repo_mfst_get_name_from_path` | 清单路径 → 仓库名 |
| `repo_mfst_get_path_from_name` | 仓库名 → 清单路径 |
| `repo_mfst_get_branch_from_path` | 清单路径 → 分支 |
| `repo_mfst_get_branch_from_name` | 仓库名 → 分支 |
| `repo_mfst_get_remote_from_name` | 仓库名 → remote |
| `repo_mfst_get_remote_from_path` | 清单路径 → remote |
| `repo_mfst_get_url_from_name` | 仓库名 → clone URL |
| `wt_os_detect` | 探测系统 / 架构 / 并行度 |
| `prompt_starship_precmd` | zsh starship 提示符钩子 |
| `prompt_starship_preexec` | zsh starship 提示符钩子 |
| `starship_zle-keymap-select` | zsh starship 键位切换钩子 |
| `starship_precmd` | bash starship 提示符钩子 |
| `starship_preexec` | bash starship 提示符钩子 |
| `starship_preexec_ps0` | bash starship 提示符钩子 |

## 键盘与历史搜索

| 键 | zsh | bash |
|---|---|---|
| `↑` / `↓` | 原生历史，不弹选择器 | 原生历史，不弹选择器 |
| `Ctrl-R` | fzf 历史搜索 | fzf 历史搜索 |
| `Ctrl-P` | 原生 `up-line-or-history`，等同 `↑` | fzf 历史搜索，等同 `Ctrl-R` |

### ↑ / ↓

**功能**：上一条 / 下一条历史命令。zsh 和 bash 都是原生行为。

**参数**：无。

**运行结果**：

```text
$ git status
$ ↑
$ git status
```

命令行出现上一条命令，不弹选择器。

![↑/↓](img/up-down.png)

### Ctrl-R

**功能**：在命令历史里搜索。zsh 用 `fzf-history-widget`，bash 用 `__fzf_history__`。

**参数**：无。打开后直接输入关键字过滤。

**运行结果**：

```text
  HIST_ALPHA_OUT
  HIST_BETA_BUILD
> HIST_GAMMA_RUN
  3/12
```

回车选中后，命令只是被填到命令行，不执行：

```text
$ HIST_GAMMA_RUN
```

可以继续编辑，再回车执行。

![Ctrl-R / fzf-history-widget](img/fzf-history.png)

### Ctrl-P

**功能**：zsh 里等同 `↑`；bash 里等同 `Ctrl-R` 的 fzf 历史搜索。

**参数**：无。bash 里打开后直接输入关键字过滤。

**运行结果**：

zsh：

```text
$ git status
$ Ctrl-P
$ git status
```

bash：

```text
  HIST_ALPHA_OUT
  HIST_BETA_BUILD
> HIST_GAMMA_RUN
  3/12
```

选中回车后同样只填到命令行，不执行。

![Ctrl-P（zsh）](img/ctrl-p-zsh.png)
![Ctrl-P（bash）](img/ctrl-p-bash.png)

### Ctrl-T

**功能**：fzf 选文件，把路径填到命令行。zsh 用 `fzf-file-widget`，bash 用 `fzf-file-widget`。

**参数**：无。打开后输入关键字过滤。

**运行结果**：

```text
$ bindkey '^T'
"^T" fzf-file-widget
```

选中回车后路径填到命令行，不执行。

![Ctrl-T / fzf-file-widget](img/fzf-file.png)
![Ctrl-T（bash）](img/ctrl-t-bash.png)

### Alt-C

**功能**：fzf 选目录并跳过去。zsh 用 `fzf-cd-widget`。

**参数**：无。

**运行结果**：

```text
$ bindkey '^[c'
"^[c" fzf-cd-widget
```

![Alt-C / fzf-cd-widget](img/fzf-cd.png)

### Ctrl-G

**功能**：打开 navi 命令速查。zsh 绑成 `_navi_widget`。

**参数**：无。打开后输入关键字过滤。

**运行结果**：

```text
$ bindkey '^G'
"^G" _navi_widget
```

![Ctrl-G](img/ctrl-g.png)

### tmux 前缀键

**功能**：tmux 默认前缀是 `Ctrl-B`。先按前缀，再按命令键。

**参数**：无。

**运行结果**：

```text
$ tmux show-options -g prefix
prefix C-b
```

常用键：`prefix + h/j/k/l` 切 pane（配置里另有 `Alt-h/j/k/l`），`prefix + Space` 已解绑。

![tmux 前缀键](img/tmux-prefix.png)

## tmux 状态栏

### tmux

**功能**：包装 `tmux`，固定使用 `terminal/tmux/tmux.conf`。

**参数**：`tmux` 自己的参数原样传入。

**运行结果**：

```text
$ tmux -V
tmux 3.4
```

![tmux -V](img/tmux-version.png)

### cpu.sh

**功能**：状态栏 CPU 指示。

**参数**：

| 参数 | 说明 |
|---|---|
| `<loadavg 文件>` | 可选，默认 `/proc/loadavg` |
| `$WTOOL_NCPU` | 可选，指定在线 CPU 数 |

**运行结果**：

```text
$ sh ~/.wtool/wtool/terminal/tmux/bin/cpu.sh
[C:0%]
```

![cpu.sh](img/cpu.png)

### mem.sh

**功能**：状态栏可用内存和可用 swap。

**参数**：

| 参数 | 说明 |
|---|---|
| `<meminfo 文件>` | 可选，默认 `/proc/meminfo` |

**运行结果**：

```text
$ sh ~/.wtool/wtool/terminal/tmux/bin/mem.sh
[M:19.5G S:68.7G]
```

读不到 `/proc/meminfo` 时输出 `[M:? S:?]`。

![mem.sh](img/mem.png)

### disk.sh

**功能**：状态栏磁盘使用量。

**参数**：无。

**运行结果**：

```text
$ sh ~/.wtool/wtool/terminal/tmux/bin/disk.sh
[/dev/sdd:288.5G C:\18.5G D:\262.4G E:\1.2T]
```

没有识别到磁盘时输出 `[]`。

![disk.sh](img/disk.png)

## musl 工具（43 个）

### 工具总表

每个工具一个项目，装单个：

```bash
wtool install tools/musl-bins/bat
```

| 命令 | 工具目录 | 功能 | 典型用法 |
|---|---|---|---|
| `bat` | `bat` | 带语法高亮的 cat | `bat file` |
| `eza` | `eza` | ls 替代 | `eza -l` |
| `delta` | `delta` | git diff 高亮 | `git diff \ |
| `dust` | `dust` | 磁盘占用树 | `dust` |
| `duf` | `duf` | 磁盘使用概览 | `duf` |
| `procs` | `procs` | 进程查看 | `procs` |
| `btm` | `bottom` | 系统监控 | `btm` |
| `jq` | `jq` | JSON 处理 | `jq . file.json` |
| `gojq` | `gojq` | JSON 查询 | `gojq . file.json` |
| `yq` | `yq` | YAML / JSON 处理 | `yq '.a' file.yaml` |
| `sd` | `sd` | 查找替换 | `sd old new file` |
| `hyperfine` | `hyperfine` | 命令基准测试 | `hyperfine 'cmd'` |
| `just` | `just` | 命令运行器 | `just` |
| `scc` | `scc` | 代码行数统计 | `scc` |
| `difft` | `difftastic` | 语法感知 diff | `difft a.c b.c` |
| `fclones` | `fclones` | 重复文件查找 | `fclones group .` |
| `shellcheck` | `shellcheck` | shell 脚本检查 | `shellcheck x.sh` |
| `shfmt` | `shfmt` | shell 格式化 | `shfmt -w x.sh` |
| `age` | `age` | 文件加密 | `age -e -r <公钥> file` |
| `b3sum` | `b3sum` | BLAKE3 校验 | `b3sum file` |
| `glow` | `glow` | Markdown 终端渲染 | `glow README.md` |
| `xh` | `xh` | HTTP 客户端 | `xh GET https://example.com` |
| `gping` | `gping` | 图形化 ping | `gping host` |
| `trip` | `trippy` | 网络诊断 | `sudo trip example.com` |
| `yazi` | `yazi` | 终端文件管理器 | `yazi` |
| `zellij` | `zellij` | 终端复用器 | `zellij` |
| `lazygit` | `lazygit` | Git TUI | `lazygit` |
| `dive` | `dive` | 镜像层分析 | `dive image:tag` |
| `fzf` | `fzf` | 模糊查找 | `fzf` |
| `zoxide` | `zoxide` | 智能 cd | `zoxide query proj` |
| `direnv` | `direnv` | 目录级环境变量 | `direnv allow` |
| `starship` | `starship` | 提示符 | `starship init zsh` |
| `navi` | `navi` | 命令速查 | `navi` |
| `rclone` | `rclone` | 云存储同步 | `rclone sync src remote:dst` |
| `mlr` | `miller` | CSV / JSON 处理 | `mlr --icsv --ojson cat data.csv` |
| `csvlens` | `csvlens` | CSV 查看 | `csvlens data.csv` |
| `watchexec` | `watchexec` | 文件变化时执行命令 | `watchexec -e py pytest` |
| `lf` | `lf` | 终端文件管理器 | `lf` |
| `micro` | `micro` | 终端编辑器 | `micro file` |
| `hexyl` | `hexyl` | 十六进制查看 | `hexyl file` |
| `qsv` | `qsv` | CSV 处理 | `qsv stats data.csv` |
| `rg` | `ripgrep` | 递归搜索 | `rg pattern` |
| `fdfind` | `fdfind` | find 替代 | `fdfind pattern` |

### 工具截图

| 命令 | 截图 | 命令 | 截图 |
|---|---|---|---|
| `bat` | <img src="img/bat-version.png" width="360"> | `eza` | <img src="img/eza-version.png" width="360"> |
| `delta` | <img src="img/delta-version.png" width="360"> | `dust` | <img src="img/dust-version.png" width="360"> |
| `duf` | <img src="img/duf-version.png" width="360"> | `procs` | <img src="img/procs-version.png" width="360"> |
| `btm` | <img src="img/btm-version.png" width="360"> | `jq` | <img src="img/jq-version.png" width="360"> |
| `gojq` | <img src="img/gojq-version.png" width="360"> | `yq` | <img src="img/yq-version.png" width="360"> |
| `sd` | <img src="img/sd-version.png" width="360"> | `hyperfine` | <img src="img/hyperfine-version.png" width="360"> |
| `just` | <img src="img/just-version.png" width="360"> | `scc` | <img src="img/scc-version.png" width="360"> |
| `difft` | <img src="img/difft-version.png" width="360"> | `fclones` | <img src="img/fclones-version.png" width="360"> |
| `shellcheck` | <img src="img/shellcheck-version.png" width="360"> | `shfmt` | <img src="img/shfmt-version.png" width="360"> |
| `age` | <img src="img/age-version.png" width="360"> | `b3sum` | <img src="img/b3sum-version.png" width="360"> |
| `glow` | <img src="img/glow-version.png" width="360"> | `xh` | <img src="img/xh-version.png" width="360"> |
| `gping` | <img src="img/gping-version.png" width="360"> | `trip` | <img src="img/trip-version.png" width="360"> |
| `yazi` | <img src="img/yazi-version.png" width="360"> | `zellij` | <img src="img/zellij-version.png" width="360"> |
| `lazygit` | <img src="img/lazygit-version.png" width="360"> | `dive` | <img src="img/dive-version.png" width="360"> |
| `fzf` | <img src="img/fzf-version.png" width="360"> | `zoxide` | <img src="img/zoxide-version.png" width="360"> |
| `direnv` | <img src="img/direnv-version.png" width="360"> | `starship` | <img src="img/starship-version.png" width="360"> |
| `navi` | <img src="img/navi-version.png" width="360"> | `rclone` | <img src="img/rclone-version.png" width="360"> |
| `mlr` | <img src="img/mlr-version.png" width="360"> | `csvlens` | <img src="img/csvlens-version.png" width="360"> |
| `watchexec` | <img src="img/watchexec-version.png" width="360"> | `lf` | <img src="img/lf-version.png" width="360"> |
| `micro` | <img src="img/micro-version.png" width="360"> | `hexyl` | <img src="img/hexyl-version.png" width="360"> |
| `qsv` | <img src="img/qsv-version.png" width="360"> | `rg` | <img src="img/rg-version.png" width="360"> |
| `fdfind` | <img src="img/fdfind-version.png" width="360"> | | |


## 其它命令（`$WTOOL_HOME/usr/bin`）

### zsh

**功能**：wtool 装的 zsh。

**参数**：zsh 自己的参数原样传入。

**运行结果**：

```text
$ zsh --version
zsh 5.9.2 (x86_64-unknown-linux-gnu)
```

![zsh --version](img/zsh-version.png)

### wpack

**功能**：Android 镜像解包 / 打包。

**参数**：

| 参数 | 说明 |
|---|---|
| `unpack <项目>/<类型> <镜像> <工作目录>` | 解包 |
| `repack <项目>/<类型> <工作目录> <输出镜像>` | 重新打包 |
| `restore <项目>/<类型> <工作目录> <路径>` | 还原一个叶子 |
| `list [项目]` | 列项目 / 类型 |
| `doctor` | 自检 |

**运行结果**：

```text
$ wpack --version
wpack 0.1.0
```

![wpack --version](img/wpack-version.png)

### dsh-remote

**功能**：手机远程查看 / 接管 DSH 会话。

**参数**：

| 参数 | 说明 |
|---|---|
| `status` | 体检：harness、隧道、推送、手机地址 |
| `serve` | 后台起 harness |
| `tunnel` / `tunnel-install` / `tunnel-uninstall` / `tunnel-status` | 反向隧道 |
| `serve-install` / `serve-status` / `serve-uninstall` | dsh web 常驻服务 |
| `broker-install` / `broker-uninstall` | token broker 常驻服务 |
| `force-restart-dsh-remote` | 重启隧道 / broker 并复验 |
| `url` | 打印手机地址 |
| `notify-test` / `notify-enable` / `notify-disable` | 推送开关 |
| `passwd` | 改中继密码 |
| `server` | 一条命令装好云上 + 家里 |
| `cloud-install` / `cloud-setup` | 阿里云侧 |
| `migrate` / `check-hooks` / `log` | 迁移 / 验证钩子 / 日志 |

**运行结果**：

```text
$ dsh-remote status
dsh-remote: …（按实际配置打印体检结果）
```

![dsh-remote --help](img/dsh-remote-help.png)

### dsh-notify

**功能**：把消息推到手机或邮箱。

**参数**：

| 参数 | 说明 |
|---|---|
| `<标题> <正文>` | 直接推一条 |
| `--test` | 推测试消息 |
| `--test --provider graph` | 只测 Graph |
| `--hook [--async]` | 从 stdin 读 hook JSON |

**运行结果**：

```text
$ dsh-notify --test
dsh-notify: 已发送（provider=…）
```

![dsh-notify --help](img/dsh-notify-help.png)

### dsh-token-broker

**功能**：把手机访问的 `/` 302 到当前 dsh web token。

**参数**：

| 参数 | 说明 |
|---|---|
| `--host <地址>` | 绑定地址，默认 `127.0.0.1` |
| `--port <端口>` | 监听端口，默认 3081 |
| `--web-port <端口>` | dsh web 端口，默认 3080 |
| `--token-file <文件>` | token 文件 |
| `--probe-timeout <秒>` | 探测超时，默认 3 |

**运行结果**：

```text
$ dsh-token-broker --help
usage: dsh-token-broker [-h] [--host HOST] [--port PORT] …
```

![dsh-token-broker --help](img/dsh-token-broker-help.png)

### dsh-remote-server

**功能**：`dsh-remote server` 的别名。

**参数**：与 `dsh-remote server` 相同。

**运行结果**：

```text
$ dsh-remote-server --help
server 不认识的参数：--help（dsh-remote help）
```

![dsh-remote-server --help](img/dsh-remote-server-help.png)

### 其它 `usr/bin` 命令

| 命令 | 用途 |
|---|---|
| `zsh-5.9.2` | 带版本号的 zsh 二进制 |
| `dsh-qr` | 把文本画成二维码 |
| `dsh-notify-graph-setup` | 一次性授权 Microsoft Graph，写 `notify.conf` |
| `dsh-web-run` | `dsh web` 的常驻包装（systemd 用） |
| `harness-remote` | 云上那半的管理器：隧道 / broker / 公网入口 |
| `dsh-force-restart-dsh-remote` | `dsh-remote force-restart-dsh-remote` 的薄封装 |

![dsh-qr --help](img/dsh-qr-help.png)
![dsh-notify-graph-setup --help](img/dsh-notify-graph-setup-help.png)
![harness-remote --help](img/harness-remote-help.png)
![dsh-force-restart-dsh-remote --help](img/dsh-force-restart-help.png)
![dsh-web-run](img/dsh-web-run-help.png)

## 常见问题

### `env -i` 下 zsh 动态模块加载不到

```bash
env -i ZDOTDIR=~/.wtool zsh
```
