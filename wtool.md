# wtool 命令

这一页是 `wtool` 命令本身。工具类命令（`ggcp` / `cdd` / `wrg` / `bat` …）见 [tutorial.md](tutorial.md)。
安装见 [install.md](install.md)。

每条命令写三块：功能、参数、运行结果。

## 安装器与引擎

### wtool

**功能**：不带参数，打印项目总览表。

**参数**：无。

**运行结果**（列有省略）：

```text
┌────────────────────────────┬──────┬────────┬────────┬────────┐
│ 项目                       │ prio │  构建  │  安装  │  卸载  │
├────────────────────────────┼──────┼────────┼────────┼────────┤
│ shell/zsh                  │ 1    │ 可执行 │ 可执行 │ 未安装 │
│ os/ubuntu                  │ 5    │ 不支持 │ 不支持 │ 不支持 │
│ wtool-base-tools           │ 5    │ 不支持 │ 可执行 │ 未安装 │
│ …                          │ …    │ …      │ …      │ …      │
└────────────────────────────┴──────┴────────┴────────┴────────┘
```

![wtool 总览表](img/wtool-table.png)

### wtool help

**功能**：打印命令清单、参数和目录说明。

**参数**：

| 参数 | 说明 |
|---|---|
| `-v` / `--verbose` | 追加 install / release 流程图和计划明细 |

**运行结果**：

```text
  ── 日常三条 ───────────────────────────────────────────────
  wtool sudo-install <项目>... [--dry-run] [--force]
  wtool install      <项目目录> [--dry-run] [--force] [--no-script] [--prune]
  wtool uninstall    <项目路径>|all [--dry-run] [--force] [--no-script]
  …
```

![wtool help](img/wtool-help.png)

### wtool version

**功能**：打印引擎版本。

**参数**：无。

**运行结果**：

```text
wtool engine 1.0.0
```

![wtool version](img/wtool-version.png)

### wtool doctor

**功能**：打印环境、路径、账本、依赖版本。

**参数**：

| 参数 | 说明 |
|---|---|
| `--quiet` / `-q` / `--json` | 只输出 `export` 行，可直接 `eval` |

**运行结果**：

```text
wtool: engine      : 1.0.0
wtool: bootstrap   : /home/you/self/wtool/wtool-base-tools
wtool: root        : /home/you/self/wtool
wtool: home        : /home/you/.wtool  (.wtool 根；WTOOL_HOME 由 rc 里那两行声明)
wtool: state       : /home/you/.wtool/var  (账本，跟着 .wtool 走)
wtool: prefix      : /home/you/.wtool/usr  (编译安装前缀)
wtool: os          : ubuntu 24.04 (noble) like=debian
wtool: arch/jobs   : x86_64 / 32
```

```bash
eval "$(wtool doctor --quiet)"
```

![wtool doctor](img/wtool-doctor.png)

### wtool status

**功能**：不带项目，列出每个项目的状态；带项目，逐列给出状态、对应命令和依据。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>` | 项目路径或末段名，如 `terminal/tmux`、`tmux` |
| `--color=auto\|always\|never` | 是否带颜色 |

**运行结果**：

```text
  PROJECT                            KIND       状态       说明
  ----------------------------------------------------------------------------------------
  terminal/tmux                      source     正常       -
  dsh-projects/dsh-conf              source     未安装      还没装（wtool bootstrap / wtool install）
  …
  61 个项目：正常 1 / 悬空 0 / 缺失 0 / 未安装 60
```

```text
项目 terminal/tmux（prio 50）  /home/you/self/wtool/terminal/tmux
  一列一个命令；状态就是看板里那一格，依据 = 「这一格是怎么看出来的」。

┌──────────┬────────┬────────────────────────┬───────────────────────────────────────────────────┐
│ 列       │  状态  │ 对应命令               │ 依据（这一格是怎么看出来的）                      │
├──────────┼────────┼────────────────────────┼───────────────────────────────────────────────────┤
│ 构建     │ 不支持 │ wtool build            │ 有 scripts/build.sh；__output/ 还没有             │
│ 安装     │ 已完成 │ wtool install          │ 有 scripts/install.sh；安装记录 3 条              │
│ 卸载     │ 可执行 │ wtool uninstall        │ 安装记录 3 条 → 撤得掉                            │
│ …        │ …      │ …                      │ …                                                 │
└──────────┴────────┴────────────────────────┴───────────────────────────────────────────────────┘
```

![wtool status](img/wtool-status.png)
![wtool status <项目>](img/wtool-status-project.png)

### wtool check

**功能**：对比声明、账本、磁盘，只报不改。

**参数**：

| 参数 | 说明 |
|---|---|
| 无 | 看全部项目 |
| `<项目>` | 只看一个项目 |

**运行结果**：

```text
$ wtool check
wtool: 一切对得上（声明 / 日志 / 磁盘）
```

退出码 0。有问题的退出码非 0，例如：

```text
wtool: [terminal/tmux] 还没装过（wtool install <路径>）
```

![wtool check](img/wtool-check.png)
![wtool check 报错](img/wtool-check-fail.png)

### wtool repair

**功能**：重建 `check` 报出来的链接和 env 块；不删除、不跑项目脚本。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>` / `all` | 修一个或全部；不给就是 `all` |
| `--dry-run` | 只打印要补什么 |

**运行结果**：

```text
$ wtool repair terminal/tmux --dry-run
wtool: ── repair terminal/tmux
project   : terminal/tmux
root      : /home/you/self/wtool/terminal/tmux
l1        : /home/you/.wtool/wtool/terminal/tmux
actions   : 1 条链（0 要新建 / 1 已在）, 2 rc
wtool:   - [dry-run] 写文件 /home/you/.wtool/var/terminal/tmux/env.zsh（内容来自 …）
wtool: repair 计划完成（1 个项目）
```

![wtool repair --dry-run](img/wtool-repair.png)

### wtool refresh-downloads

**功能**：重写 `download.md` 里的下载链接块。

**参数**：

| 参数 | 说明 |
|---|---|
| `--dry-run` | 只打印会改哪个文件 |
| `wtool docs refresh` | 同一条命令的另一种写法 |

**运行结果**：

```text
$ wtool refresh-downloads --dry-run
wtool:   - [dry-run] 刷新下载链接块: wtool-doc/download.md
```

![wtool refresh-downloads --dry-run](img/wtool-refresh.png)

### wtool kill-self-forever

**功能**：删除 wtool 的链接、账本、rc 两行和本机日志。不可逆。

**参数**：

| 参数 | 说明 |
|---|---|
| `--dry-run` | 只打印会删什么 |
| `--yes` | 跳过逐字确认（脚本用） |

**运行结果**（节选）：

```text
wtool: kill-self-forever 会删掉下面这些（**不可逆**）：

  【$HOME 里的软链】1 条，都是 wtool 自己建的（只删还指向 wtool 的）
  【$WTOOL_HOME（.wtool 根）】/home/you/.wtool
  【账本】/home/you/.wtool/var
  【rc 里 wtool 的东西】/home/you/.zshrc 和 /home/you/.bashrc 里 wtool 那两行/旧块
  【本机日志】/home/you/.local/state/wtool

确认要删，请逐字输入 KILL-SELF-FOREVER：
```

![wtool kill-self-forever --dry-run](img/wtool-kill.png)

### 内部命令

这些名字不是给日常用的。

| 名字 | 怎么敲 | 用途 |
|---|---|---|
| `_complete` | `wtool _complete <词>` | Tab 补全候选 |
| `_layer-save` | `wtool _layer-save <项目> --image=<镜像>` | docker 镜像 → `__layer/` |
| `_layer-load` | `wtool _layer-load <项目>` | `__layer/` → docker |
| `kind-caps` | `python3 lib/wtool_plan.py kind-caps --command <命令> --root <工作区>` | 查项目支持哪些命令 |
| `health` | `python3 lib/wtool_plan.py health --root <工作区>` | 项目健康状态 |
| `render-env-file` | `python3 lib/wtool_plan.py render-env-file --home … --state … --shell zsh` | 生成 `env.zsh` / `env.bash` |
| `render-zshenv` | `python3 lib/wtool_plan.py render-zshenv` | 生成 `$WTOOL_HOME/.zshenv` |

`wtool kind-caps`、`wtool health`、`wtool render-env-file` 都是未知命令。

![wtool _complete](img/wtool-complete.png)

## 项目管理

### wtool install

**功能**：安装一个项目：建 `$WTOOL_HOME/wtool/<路径>` 链接、写 env 块、跑项目 `install.sh`。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目路径>` | 相对工作区根，如 `terminal/tmux`；也认绝对路径和末段名 |
| `all` | 装所有项目，等同 `wtool bootstrap` |
| `--dry-run` | 只打印计划 |
| `--force` | 目录有未提交改动也装 |
| `--no-script` | 不跑项目自己的 `install.sh` |
| `--prune` | 清掉清单里已删的旧软链 |

**运行结果**：

```text
$ wtool install terminal/tmux
wtool: 规划 /home/you/self/wtool/terminal/tmux
project   : terminal/tmux
root      : /home/you/self/wtool/terminal/tmux
l1        : /home/you/.wtool/wtool/terminal/tmux
actions   : 1 条链（0 要新建 / 1 已在）, 2 rc
wtool: project: terminal/tmux
wtool:   - check /home/you/.wtool/wtool/terminal/tmux -> /home/you/self/wtool/terminal/tmux（已在，只记账）
wtool: install 完成
```

![wtool install](img/wtool-install.png)

### wtool uninstall

**功能**：撤销一个项目或全部项目。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目路径>` / `all` | 项目写完整路径；`all` 撤所有装过的项目 |
| `--dry-run` | 只打印计划 |
| `--force` | 忽略检查 |
| `--no-script` | 不跑项目自己的 `install.sh --uninstall` |

**运行结果**：

```text
$ wtool uninstall terminal/tmux
project   : terminal/tmux
actions   : 0 rc
wtool: project: terminal/tmux
wtool: uninstall 完成
```

![wtool uninstall](img/wtool-uninstall.png)

### wtool move

**功能**：项目改名：卸旧的、移动目录、装新的。

**参数**：

| 参数 | 说明 |
|---|---|
| `<旧路径> <新路径>` | 相对工作区根或绝对路径 |
| `--dry-run` | 只打印三步计划 |
| `--force` | 忽略检查 |
| `--no-script` | 不跑项目脚本 |

**运行结果**：

```text
$ wtool move terminal/tmux terminal/tmux2 --dry-run
wtool: [dry-run] 改名计划：terminal/tmux  →  terminal/tmux2
wtool:   - [dry-run]   1/3 wtool uninstall terminal/tmux
wtool:   - [dry-run]   2/3 mv /home/you/self/wtool/terminal/tmux  →  /home/you/self/wtool/terminal/tmux2
wtool:   - [dry-run]   3/3 wtool install /home/you/self/wtool/terminal/tmux2
wtool: [dry-run] 目录、state、$HOME 软链都没碰（--dry-run）
```

![wtool move --dry-run](img/wtool-move.png)

### wtool bootstrap

**功能**：按 priority 顺序把所有项目 `install` 一遍。

**参数**：

| 参数 | 说明 |
|---|---|
| `--dry-run` | 只打印计划 |
| `--force` | 目录有未提交改动也装 |
| `--prune` | 每个项目顺手清旧软链 |

**运行结果**（节选）：

```text
wtool: 扫描项目: /home/you/self/wtool

=== [1] shell/zsh ===
…
共 54 个项目：已安装 0（待装 53），已发布 0（待发 52），待构建 1
```

需要产物的项目会跳过；先 `wtool build <项目>` 或 `wtool download-release <项目>` + `wtool unpack-release <项目>`。

![wtool bootstrap --dry-run](img/wtool-bootstrap.png)

### wtool init

**功能**：新建项目模板：`wtool.xml`、`env.zsh`、`env.bash`、`scripts/`。

**参数**：

| 参数 | 说明 |
|---|---|
| `<目录>` | 工作区里的目录，如 `demo/foo` |
| `--priority N` | priority，默认 100 |
| `--with-build` | 生成 `scripts/build.sh` |
| `--with-install` | 生成 `scripts/install.sh` |
| `--all` | 两个脚本都生成 |

**运行结果**：

```text
wtool: 生成 wtool.xml
wtool: 生成 env.zsh
wtool: 生成 env.bash
wtool: 生成 scripts/build.sh  (能构建)
wtool: 生成 scripts/install.sh  (能安装)
wtool: 已生成项目: demo/foo  (id=demo/foo priority=55)
wtool: 下一步：填 wtool.xml，然后 wtool validate demo/foo
```

![wtool init](img/wtool-init.png)

### wtool validate

**功能**：检查项目的 `wtool.xml`。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目目录>` | 要检查的目录 |

**运行结果**：

```text
$ wtool validate terminal/tmux
ok: terminal/tmux
```

有错时打印 `error: …`，退出码非 0。

![wtool validate](img/wtool-validate.png)

## 系统层

`os/ubuntu` 声明了三项：apt 源、基础软件包、重型工具链（`WTOOL_HEAVY=1` 才装）。

### wtool sudo-install

**功能**：装系统层：`/etc` 下的文件、apt 包、playbook。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` | 一个或多个项目，如 `os/ubuntu` |
| `--dry-run` | 只打印计划 |
| `--force` | 忽略检查 |

**运行结果**：

```text
$ wtool sudo-install os/ubuntu --dry-run
wtool: ── os/ubuntu  系统层
wtool: warning: when=os:ubuntu,env:WTOOL_HEAVY 不匹配，跳过任务 重型工具链（需要 WTOOL_HEAVY=1）
project   : os/ubuntu
actions   : 1 sysfile, 0 source, 1 task
wtool: 系统文件[replace]: /etc/apt/sources.list.d/ubuntu.sources  (apt 源（跟随 install.sh 里挑的那个镜像）)
wtool:   - [dry-run] 备份 /etc/apt/sources.list.d/ubuntu.sources
wtool:   - [dry-run] 写系统文件 /etc/apt/sources.list.d/ubuntu.sources
wtool: task[ansible]: 基础软件包（常用工具 + 搜索 + 构建基础）
wtool: sudo-install 完成: os/ubuntu
```

![wtool sudo-install --dry-run](img/wtool-sudo-install.png)

### wtool sudo-uninstall

**功能**：撤销系统层：还原 `/etc` 文件，卸掉这次装进来的 apt 包。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` / `all` | 要撤的项目；`all` 撤所有有系统层记录的项目 |
| `--dry-run` | 只打印计划 |
| `--force` | 忽略检查 |

**运行结果**：

```text
$ wtool sudo-uninstall os/ubuntu
wtool: 还原系统文件[replace]: /etc/apt/sources.list.d/ubuntu.sources  (apt 源)
wtool: sudo-uninstall 完成: os/ubuntu
```

![wtool sudo-uninstall](img/wtool-sudo-uninstall.png)

### wtool sudo-bootstrap

**功能**：对所有项目跑一遍 `sudo-install`。

**参数**：

| 参数 | 说明 |
|---|---|
| `--dry-run` | 只打印计划 |
| `--force` | 忽略检查 |

**运行结果**：

```text
=== [5] os/ubuntu ===
wtool: ── os/ubuntu  系统层
project   : os/ubuntu
actions   : 1 sysfile, 0 source, 1 task
wtool: sudo-install 完成: os/ubuntu
wtool: sudo-bootstrap 完成（1 个项目）
```

![wtool sudo-bootstrap --dry-run](img/wtool-sudo-bootstrap.png)

## 构建、打包与发布

| 项目类型 | 可用命令 |
|---|---|
| `kind="source"` | `install`、离线包 |
| `kind="muslbin"` | `download-release`、`unpack-release`、`install`、离线包 |
| `kind="docker"` | `build`、`pack-release`、`publish-release`、`download-release`、`unpack-release`、层命令、`install`、离线包 |

### wtool build

**功能**：构建项目，产物写进 `__output/`。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` / `all` | 要构建的项目 |
| `--dry-run` | 只打印计划 |
| `--force` | 忽略机器门槛检查 |
| `--target=<目标>` | 只构建某个发行版，如 `ubuntu_24.04` |
| `--jobs=N` | 并行层数 |
| `--rebuild` | 无视已完成标记，强制重跑 |

**运行结果**：

```text
$ wtool build shell/zsh --dry-run
wtool: ── shell/zsh
wtool:   方式 : docker
wtool: ── shell/zsh  目标 ubuntu_24.04（基础镜像 ubuntu:24.04）
wtool:   - [dry-run] main ← - → wtool/zsh-usr:ubuntu_24.04
wtool:   -          容器里: sh /proj/scripts/build.sh --in-docker --target=ubuntu_24.04
wtool: dry-run：以上 3 个目标的计划，什么都没执行（没有起容器、没写 __layer/ / __output/）
wtool: build 完成（1 个项目）
```

![wtool build --dry-run](img/wtool-build.png)

### wtool download-release

**功能**：把包下载到项目的 `__release/`，只下载、不解包。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` / `all` | 要下载的项目；不给就列出可下载的项目 |
| `--dry-run` | 只打印要下载的 URL |

**运行结果**：

```text
$ wtool download-release tools/musl-bins/bat --dry-run
wtool: ── tools/musl-bins/bat
wtool:   声明 : wtool.xml 的 <muslbin>（上游二进制；tag v0.26.1）
wtool:   落点 : __release/
wtool:   - [dry-run] bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz  ← https://github.com/sharkdp/bat/releases/download/v0.26.1/…
wtool: download-release 完成（1 个项目）
```

![wtool download-release --dry-run](img/wtool-download.png)

### wtool unpack-release

**功能**：按 `scripts/release.json` 校验并解开 `__release/` 里的包，写进 `__output/`。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` / `all` | 要解的项目 |
| `--from=<目录>` | 包在别的目录 |
| `--dry-run` | 只打印计划 |

**运行结果**：

```text
$ wtool unpack-release tools/musl-bins/bat --dry-run
wtool: ── bat
wtool:   - [dry-run] 从 bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz 里取成员 [bat-v0.26.1-x86_64-unknown-linux-musl/bat] → …/__output/usr/bin/bat（并校验 sha256）
wtool: dry-run：以上 1 条的计划，什么都没解开（__output/ 一个字节都没写）
wtool: unpack-release 完成（1 个项目）
```

![wtool unpack-release --dry-run](img/wtool-unpack.png)

### wtool pack-release

**功能**：打包到项目的 `__release/`：`source.zip`、`release.zip`、`dist.json`、校验文件，并写项目里的 `docs/download.md`。只适用于 `kind="docker"`。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` | 要打包的项目 |
| `--tag=<tag>` | 指定 tag，默认按模板 |
| `--repo=<owner/repo>` | 指定目标仓，默认取项目 remote |
| `--volume-size=<大小>` | 分卷大小，默认 `32M` |
| `--dry-run` | 只打印计划 |
| `--force` | 忽略检查 |

**运行结果**：

```text
$ wtool pack-release shell/zsh --dry-run
wtool: ── shell/zsh
wtool:   目标仓 : allinkernel/wtool-zsh
wtool:   tag    : snapshot-2026-10-23
wtool:   卷大小 : 32M
wtool:   - [dry-run] source.zip  ← 1743 个文件
wtool:   - [dry-run] release.zip ← 3829 个文件 + 声明面 wtool.xml,env.zsh,env.bash
wtool:   - [dry-run] 写 …/shell/zsh/__release/：dist.json、source-hash.txt、release-hash.txt、超 32M 就切分卷
wtool: pack-release 完成（1 个项目）
```

`kind="source"` / `kind="muslbin"` 会报不支持：

```text
wtool: 'terminal/tmux' 是 kind=source（纯源码项目），不支持 pack-release —— 它没有产物包 —— 源码即产物，离线包走 pack-offline-release
```

![wtool pack-release --dry-run](img/wtool-pack.png)
![wtool pack-release 失败](img/wtool-pack-fail.png)

### wtool publish-release

**功能**：把 `__release/` 里的包上传到 GitHub Release，上传成功后写 `scripts/release.json`。只适用于 `kind="docker"`。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` | 要发布的项目；不给就发所有可发布项目 |
| `--tag=<tag>` | 指定 tag |
| `--dry-run` | 只打印上传清单 |
| `--force` | 同一 commit 重发时不再询问 |
| `--allow-foreign` | 允许发到第三方仓 |
| `--out=<目录>` | 发布后另拷一份产物 |

**运行结果**：

```text
$ wtool publish-release shell/zsh --dry-run
wtool: ── shell/zsh
wtool:   目标仓 : allinkernel/wtool-zsh
wtool:   tag    : snapshot-2026-10-23
wtool:   target : 970154c2458686af57032b969d10cb01db1b08cf（这一版打包用的 commit）
wtool:   - [dry-run] 上传 5 个文件 → allinkernel/wtool-zsh snapshot-2026-10-23
wtool:   - [dry-run] 资产（5 个）: dist.json release-hash.txt release.zip source-hash.txt source.zip
wtool:   - [dry-run] 之后写 scripts/release.json（记得提交）
wtool:   - [dry-run] 刷新下载链接块: wtool-doc/download.md
```

![wtool publish-release --dry-run](img/wtool-publish.png)

### wtool pack-offline-release

**功能**：打离线自足包。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` | 逐项目打：`source-offline.zip`、`release-offline.zip`、`wtool-base-tools.tar.gz` |
| `each` | 所有项目逐项目各打一个 |
| `all` | 整机迁移包：`wtool-all-ubuntu<版本>.tar.gz` |
| `--volume-size=<大小>` | 分卷大小，默认 `32M` |
| `--os-version=<22.04\|24.04\|26.04>` | 整机包资产名和别名链的起始版本 |
| `--check` / `--no-check` | 整机包打完是否再检查一遍，默认检查 |
| `--check-only` | 只检查已有整机包 |
| `--out=<目录>` | 整机包输出目录，默认工作区 `__release/` |
| `--dry-run` | 只打印计划 |

**运行结果**（逐项目）：

```text
$ wtool pack-offline-release terminal/tmux --dry-run
wtool: ── terminal/tmux
wtool:   卷大小 : 32M
wtool:   - [dry-run] 产 …/terminal/tmux/__release/source-offline.zip（16 个文件，kind=source）
wtool:   - [dry-run] 包内第一层：wtool/terminal/tmux/（解压即合并进 $WTOOL_HOME）
wtool:   - [dry-run] 旁边写 source-offline.zip.sha256；超 32M 就切分卷 + check-hash.sh（不依赖 wtool）
wtool: pack-offline-release 完成（1 个项目）
```

**运行结果**（整机包，节选）：

```text
   项目集合: 52 个（docker 1 / muslbin 43 / source 8）
   asset     : wtool-all-ubuntu24.04.tar.gz
   files     : 7073 个（原样拷；无 usr/ 无 var/ 无 L1 链）
wtool:   - [dry-run] 形状：顶层 .wtool/（env + .zshenv + install.sh 链 + wtool/<项目> 实体）
wtool:   - [dry-run] **没有** usr/、**没有** var/、**没有** L1 链 —— 目标机上是「全部未安装」
```

![wtool pack-offline-release --dry-run](img/wtool-pack-offline.png)

### wtool publish-offline-release

**功能**：把离线包上传到 `offline-<日期>` 那个 release 页。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` / `each` | 逐项目上传 |
| `all` | 上传整机迁移包到 `wtool-doc` 的 release 页 |
| `--tag=<tag>` | 必须带 `offline`，默认 `offline-<今天>` |
| `--repo=<owner/name>` | 目标仓 |
| `--target=<sha>` | 指定 target commit |
| `--os-version=<版本>` | 整机包版本 |
| `--out=<目录>` | 整机包所在目录 |
| `--dry-run` | 只打印上传清单 |
| `--force` | 忽略检查 |
| `--allow-foreign` | 允许发到第三方仓 |

**运行结果**：

```text
$ wtool publish-offline-release shell/zsh --dry-run
wtool: ── shell/zsh
wtool:   目标仓 : allinkernel/wtool-zsh
wtool:   tag    : offline-2026-10-23（离线族；开发机那族是另一个 tag）
wtool:   - [dry-run] 上传 2 个文件 → allinkernel/wtool-zsh offline-2026-10-23
wtool:   - [dry-run] 资产（2 个）: release-offline.zip release-offline.zip.sha256
wtool:   - [dry-run] 之后把 offlineTag=offline-2026-10-23 写进 scripts/release.json（记得提交）
```

![wtool publish-offline-release --dry-run](img/wtool-publish-offline.png)

## 容器层

### wtool unpack-layer

**功能**：把 `__layer/<target>/` 里的层解成安装产物，写进 `__output/`。不联网、不要 docker。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>` | 项目路径 |
| `--target=<目标>` | 只解某个发行版 |
| `--layer=<层名>` | 只解某一层 |
| `--output=<目录>` | 输出目录 |
| `--dry-run` | 只打印计划 |

**运行结果**：

```text
$ wtool unpack-layer shell/zsh --dry-run
wtool: ── shell/zsh  __layer/ubuntu_22.04/main → /home/you/self/wtool/shell/zsh/__output/ubuntu_22.04/
wtool:   - [dry-run] 读顶层 blob → payload/ + OWNED.tsv
```

![wtool unpack-layer --dry-run](img/wtool-unpack-layer.png)

### wtool push-layer

**功能**：把 `__layer/<target>/` 里的层镜像推到镜像仓库。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` | 项目路径 |
| `--registry=<前缀>` | 镜像仓库前缀，也可用 `$WTOOL_LAYER_REGISTRY` |
| `--target=<目标>` | 只推某个发行版 |
| `--layer=<层名>` | 只推某一层 |
| `--dry-run` | 只打印计划 |

**运行结果**：

```text
$ wtool push-layer shell/zsh --registry=registry.example.com/wtool --dry-run
wtool: ── shell/zsh  __layer/ubuntu_22.04/ → registry.example.com/wtool/zsh
wtool:   - [dry-run] main → registry.example.com/wtool/zsh:main-ubuntu_22.04
wtool: push-layer 完成（0 个项目）
```

![wtool push-layer --dry-run](img/wtool-push-layer.png)

### wtool pull-layer

**功能**：从镜像仓库把层镜像拉到 `__layer/`。目标机不需要 docker。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>...` | 项目路径 |
| `--registry=<前缀>` | 镜像仓库前缀，也可用 `$WTOOL_LAYER_REGISTRY` |
| `--target=<目标>` | 只拉某个发行版 |
| `--layer=<层名>` | 只拉某一层 |
| `--dry-run` | 只打印计划 |

**运行结果**：

```text
wtool: ── shell/zsh  ← registry.example.com/wtool/zsh:*-ubuntu_22.04
wtool: main（blob 只存一份；整个 layout 1.2G）
wtool: pull-layer 完成（1 个项目）—— 接着 wtool unpack-layer <项目>
```

仓库不存在、没登录时：

```text
wtool: error: 读不到 registry.example.com/wtool/zsh 的 tag 列表（仓库不存在？没登录？skopeo login <域名>）
```

![wtool pull-layer --dry-run](img/wtool-pull-layer.png)

### wtool _layer-save

**功能**：把 docker 里的镜像存进项目的 `__layer/<target>/`。内部命令。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>` | 项目路径 |
| `--image=<镜像>` | 必填 |
| `--target=<目标>` | 发行版；不给就从 `__output/` 推 |
| `--layer=<层名>` | 层名；不给就从镜像 tag 推 |

**运行结果**：

```text
wtool: error: 用法: wtool _layer-save <项目> --image=<镜像> [--target=<os_ver>] [--layer=<层名>]
```

![wtool _layer-save](img/wtool-layer-save.png)

### wtool _layer-load

**功能**：把 `__layer/<target>/` 里的镜像装回 docker。内部命令。

**参数**：

| 参数 | 说明 |
|---|---|
| `<项目>` | 项目路径 |
| `--target=<目标>` | 发行版 |

**运行结果**：

```text
wtool: error: 用法: wtool _layer-load <项目> [--target=<os_ver>]
```

![wtool _layer-load](img/wtool-layer-load.png)

## 常见问题

### `wtool` 命令找不到

```bash
exec $SHELL
```

还不行就看 rc 末尾有没有这两行：

```bash
export WTOOL_HOME=~/.wtool
source ${WTOOL_HOME}/env.zsh
```

### `wtool check` 退出码是 0，但项目没装

```bash
wtool status
```

`wtool check` rc=0 只表示声明、账本、磁盘一致。

### `wtool check` 报对不上

```bash
wtool repair <项目>
wtool uninstall <旧路径> --no-script
wtool install <项目>
```

### 按 Tab 补出来的是文件名

```bash
exec $SHELL
```

还不行：

```bash
wtool install wtool-base-tools --force
exec $SHELL
```

### 没有 sudo

跳过 `sudo-*`，其余照常：

```bash
./install.sh
exec $SHELL
wtool bootstrap
```

### 删掉 `~/.wtool`

```bash
wtool uninstall all
wtool kill-self-forever
```

### `wtool install` 报「不是 git 仓库」

```bash
wtool install <项目> --force
```

### 项目里是 `output/` 而不是 `__output/`

```bash
cd <项目目录>
mv output __output
mv release __release
mv layer __layer
```

### `install.sh` 装包时看起来卡住

每 5 秒会打印一行进度：

```text
wtool-install:     还在装…（30 秒）  · Get:3 http://… 45.2 MB/120 MB
```

有这行就还在跑。
