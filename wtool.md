# wtool 命令

这一页是 `wtool` 命令本身。工具类命令（`ggcp` / `cdd` / `wrg` / `bat` …）见 [tutorial.md](tutorial.md)，
dsh 那组见 [dsh-tutorial.md](dsh-tutorial.md)，安装见 [install.md](install.md)。

## 安装器与引擎

### wtool

**功能**：不带参数，打印项目总览表（每个项目能跑哪些命令、装没装）。

**常用**：

```sh
wtool                     # 总览表
wtool | head -8           # 只看前几行
```

![wtool 总览表](img/wtool-table.png)

### wtool help

**功能**：打印命令清单、参数和目录说明。

**常用**：

```sh
wtool help                # 命令清单
wtool help -v             # 追加 install / release 流程图和计划明细
```

![wtool help](img/wtool-help.png)

### wtool version

**功能**：打印引擎版本。

**常用**：

```sh
wtool version
```

![wtool version](img/wtool-version.png)

### wtool doctor

**功能**：打印环境、路径、账本、依赖版本。

**常用**：

```sh
wtool doctor              # 人看
wtool doctor --quiet      # 只输出 export 行，可以直接 eval
eval "$(wtool doctor --quiet)"
```

![wtool doctor](img/wtool-doctor.png)

### wtool status

**功能**：不带项目，列出每个项目的状态；带项目，逐列给出状态、对应命令和依据。

**常用**：

```sh
wtool status                      # 全部项目：正常 / 悬空 / 缺失 / 未安装 + 汇总
wtool status terminal/tmux        # 一个项目：一行一个判断依据
wtool status --color=never        # 日志里用
```

![wtool status](img/wtool-status.png)
![wtool status <项目>](img/wtool-status-project.png)

### wtool check

**功能**：对比声明、账本、磁盘，只报不改。

**常用**：

```sh
wtool check                       # rc=0 = 一致；有问题逐条列出，rc 非 0
wtool check terminal/tmux         # 只看一个项目
```

**提示**：`check` rc=0 ≠ 已装 —— 它只表示三者一致，装没装看 `wtool status`。

![wtool check](img/wtool-check.png)
![wtool check 报错](img/wtool-check-fail.png)

### wtool repair

**功能**：重建 `check` 报出来的链接和 env 块；不删除、不跑项目脚本。

**常用**：

```sh
wtool repair terminal/tmux --dry-run   # 先看要补什么
wtool repair terminal/tmux             # 补一个
wtool repair                           # 补全部（不给就是 all）
```

![wtool repair --dry-run](img/wtool-repair.png)

### wtool refresh-downloads

**功能**：重写 `download.md` 里的下载链接块。

**常用**：

```sh
wtool refresh-downloads --dry-run      # 只打印会改哪个文件
wtool refresh-downloads
```

![wtool refresh-downloads --dry-run](img/wtool-refresh.png)

### wtool kill-self-forever

**功能**：删除 wtool 的链接、账本、rc 两行和本机日志。**不可逆**。

**常用**：

```sh
wtool kill-self-forever --dry-run      # 先看会删什么
wtool kill-self-forever                # 逐字输入 KILL-SELF-FOREVER 才动手
```

![wtool kill-self-forever --dry-run](img/wtool-kill.png)

### 内部命令

不是给日常敲的；补全和引擎内部脚本在用。

```sh
wtool _complete install                          # Tab 补全候选
wtool _layer-save <项目> --image=<镜像>           # docker 镜像 → __layer/
wtool _layer-load <项目>                          # __layer/ → docker
python3 lib/wtool_plan.py kind-caps --command install --root <工作区>   # 查项目支持哪些命令
```

![wtool _complete](img/wtool-complete.png)

## 项目管理

### wtool install

**功能**：装一个项目：建 `$WTOOL_HOME/wtool/<路径>` 链接、写 env 块、跑项目 `install.sh`。

**常用**：

```sh
wtool install terminal/tmux            # 装一个（也认末段名 tmux）
wtool install all                      # 装全部，等于 wtool bootstrap
wtool install terminal/tmux --dry-run   # 只打印计划
```

**提示**：`--force` 允许目录有未提交改动；`--no-script` 不跑项目脚本；`--prune` 清掉清单里已删的旧软链。

![wtool install](img/wtool-install.png)

### wtool uninstall

**功能**：撤销一个项目或全部项目。

**常用**：

```sh
wtool uninstall terminal/tmux           # 撤一个
wtool uninstall all                     # 撤所有装过的
wtool uninstall terminal/tmux --dry-run  # 只看计划
```

**提示**：`--no-script` 不跑项目自己的 `install.sh --uninstall`（撤旧账时常用）。

![wtool uninstall](img/wtool-uninstall.png)

### wtool move

**功能**：项目改名：卸旧的、移动目录、装新的。

**常用**：

```sh
wtool move terminal/tmux terminal/tmux2 --dry-run   # 看三步计划
wtool move terminal/tmux terminal/tmux2             # 真做
```

![wtool move --dry-run](img/wtool-move.png)

### wtool bootstrap

**功能**：按 priority 顺序把所有项目 `install` 一遍。

**常用**：

```sh
wtool bootstrap --dry-run --force       # 看会装几个、跳过几个
wtool bootstrap                         # 真装
```

**提示**：要产物的项目会跳过 —— 先 `wtool build <项目>`，或 `wtool download-release` + `wtool unpack-release`。

![wtool bootstrap --dry-run](img/wtool-bootstrap.png)

### wtool init

**功能**：新建项目模板：`wtool.xml`、`env.zsh`、`env.bash`、`scripts/`。

**常用**：

```sh
wtool init demo/new --priority 55         # 只生成 wtool.xml + env
wtool init demo/new --all                 # 连 scripts/build.sh、install.sh 一起
```

![wtool init](img/wtool-init.png)

### wtool validate

**功能**：检查项目的 `wtool.xml`。

**常用**：

```sh
wtool validate terminal/tmux             # ok: terminal/tmux
```

**提示**：有错时打印 `error: …`，退出码非 0。

![wtool validate](img/wtool-validate.png)

## 系统层

`os/ubuntu` 声明了三项：apt 源、基础软件包、重型工具链（`WTOOL_HEAVY=1` 才装）。

### wtool sudo-install

**功能**：装系统层：`/etc` 下的文件、apt 包、playbook。

**常用**：

```sh
wtool sudo-install os/ubuntu --dry-run    # 先看计划（不要 sudo 也能跑）
wtool sudo-install os/ubuntu              # 真装
```

![wtool sudo-install --dry-run](img/wtool-sudo-install.png)

### wtool sudo-uninstall

**功能**：撤销系统层：还原 `/etc` 文件，卸掉这次装进来的 apt 包。

**常用**：

```sh
wtool sudo-uninstall os/ubuntu            # 撤一个
wtool sudo-uninstall all                  # 撤所有有系统层记录的
```

![wtool sudo-uninstall](img/wtool-sudo-uninstall.png)

### wtool sudo-bootstrap

**功能**：对所有项目跑一遍 `sudo-install`。

**常用**：

```sh
wtool sudo-bootstrap --dry-run            # 看有几个项目有系统层
wtool sudo-bootstrap
```

![wtool sudo-bootstrap --dry-run](img/wtool-sudo-bootstrap.png)

## 构建、打包与发布

| 项目类型 | 可用命令 |
|---|---|
| `kind="source"` | `install`、离线包 |
| `kind="muslbin"` | `download-release`、`unpack-release`、`install`、离线包 |
| `kind="docker"` | `build`、`pack-release`、`publish-release`、层命令、`install`、离线包 |

### wtool build

**功能**：构建项目，产物写进 `__output/`。

**常用**：

```sh
wtool build shell/zsh --dry-run           # 看目标、看容器命令
wtool build shell/zsh                     # 真构建
wtool build all --rebuild                 # 全部重跑
```

**提示**：`--target=<目标>` 只构建某个发行版；`--jobs=N` 并行层数；`--force` 越过机器门槛检查。

![wtool build --dry-run](img/wtool-build.png)

### wtool download-release

**功能**：把包下载到项目的 `__release/`，只下载、不解包。

**常用**：

```sh
wtool download-release tools/musl-bins/bat --dry-run   # 只打印 URL
wtool download-release tools/musl-bins/bat
```

![wtool download-release --dry-run](img/wtool-download.png)

### wtool unpack-release

**功能**：按 `scripts/release.json` 校验并解开 `__release/` 里的包，写进 `__output/`。

**常用**：

```sh
wtool unpack-release tools/musl-bins/bat --dry-run      # 看要取哪个成员
wtool unpack-release tools/musl-bins/bat
```

**提示**：包在别的目录用 `--from=<目录>`。

![wtool unpack-release --dry-run](img/wtool-unpack.png)

### wtool pack-release

**功能**：打包到项目的 `__release/`：`source.zip`、`release.zip`、`dist.json`、校验文件，并写 `docs/download.md`。只适用于 `kind="docker"`。

**常用**：

```sh
wtool pack-release shell/zsh --dry-run    # 看 tag、目标仓、卷大小
wtool pack-release shell/zsh
```

**提示**：`kind="source"` / `kind="muslbin"` 会报不支持 —— 源码即产物，要离线包走 `pack-offline-release`。

![wtool pack-release --dry-run](img/wtool-pack.png)
![wtool pack-release 失败](img/wtool-pack-fail.png)

### wtool publish-release

**功能**：把 `__release/` 里的包上传到 GitHub Release，成功后写 `scripts/release.json`。只适用于 `kind="docker"`。

**常用**：

```sh
wtool publish-release shell/zsh --dry-run   # 看上传清单
wtool publish-release shell/zsh
```

**提示**：`--tag=<tag>` 指定 tag；`--force` 同一 commit 重发不再问；`--allow-foreign` 允许发到第三方仓。

![wtool publish-release --dry-run](img/wtool-publish.png)

### wtool pack-offline-release

**功能**：打离线自足包（目标机不联网也能装）。

**常用**：

```sh
wtool pack-offline-release terminal/tmux --dry-run   # 一个项目
wtool pack-offline-release each                      # 所有项目各打一个
wtool pack-offline-release all                       # 整机迁移包 wtool-all-ubuntu<版本>.tar.gz
```

**提示**：`--volume-size=<大小>` 分卷（默认 32M）；整机包可用 `--check-only` 只检查已有包。

![wtool pack-offline-release --dry-run](img/wtool-pack-offline.png)

### wtool publish-offline-release

**功能**：把离线包上传到 `offline-<日期>` 那个 release 页。

**常用**：

```sh
wtool publish-offline-release shell/zsh --dry-run   # 逐项目
wtool publish-offline-release all                   # 整机包 → wtool-doc 的 release 页
```

**提示**：tag 必须带 `offline`，默认 `offline-<今天>`。

![wtool publish-offline-release --dry-run](img/wtool-publish-offline.png)

## 容器层

### wtool unpack-layer

**功能**：把 `__layer/<target>/` 里的层解成安装产物，写进 `__output/`。不联网、不要 docker。

**常用**：

```sh
wtool unpack-layer shell/zsh --dry-run    # 看读哪个 blob
wtool unpack-layer shell/zsh
```

![wtool unpack-layer --dry-run](img/wtool-unpack-layer.png)

### wtool push-layer

**功能**：把 `__layer/<target>/` 里的层镜像推到镜像仓库。

**常用**：

```sh
wtool push-layer shell/zsh --registry=registry.example.com/wtool --dry-run
wtool push-layer shell/zsh --registry=registry.example.com/wtool
```

**提示**：仓库前缀也可用 `$WTOOL_LAYER_REGISTRY`；`--target=` / `--layer=` 只推某一层。

![wtool push-layer --dry-run](img/wtool-push-layer.png)

### wtool pull-layer

**功能**：从镜像仓库把层镜像拉到 `__layer/`。目标机不需要 docker。

**常用**：

```sh
wtool pull-layer shell/zsh --registry=registry.example.com/wtool --dry-run
wtool pull-layer shell/zsh --registry=registry.example.com/wtool
```

**提示**：拉完接着 `wtool unpack-layer <项目>`；读不到 tag 列表就先 `skopeo login <域名>`。

![wtool pull-layer --dry-run](img/wtool-pull-layer.png)

### wtool _layer-save

**功能**：把 docker 里的镜像存进项目的 `__layer/<target>/`。内部命令。

```sh
wtool _layer-save <项目> --image=<镜像> [--target=<os_ver>] [--layer=<层名>]
```

![wtool _layer-save](img/wtool-layer-save.png)

### wtool _layer-load

**功能**：把 `__layer/<target>/` 里的镜像装回 docker。内部命令。

```sh
wtool _layer-load <项目> [--target=<os_ver>]
```

![wtool _layer-load](img/wtool-layer-load.png)

## 常见问题

### `wtool` 命令找不到

```sh
exec $SHELL
```

还不行：看 rc 末尾有没有 `export WTOOL_HOME=~/.wtool` + `source ${WTOOL_HOME}/env.zsh`。

### `wtool check` 退出码是 0，但项目没装

`check` rc=0 只表示声明、账本、磁盘一致；装没装用 `wtool status` 看。

### `wtool check` 报对不上

软链/块缺了 → `wtool repair <项目>`；旧路径上留下的账 → `wtool uninstall <旧路径> --no-script`。

### 按 Tab 补出来的是文件名

`exec $SHELL`；还不行 `wtool install wtool-base-tools --force` 再 `exec $SHELL`。

### 没有 sudo

跳过所有 `sudo-*`，其余照常：`./install.sh` → `exec $SHELL` → `wtool bootstrap`。

### 删掉 `~/.wtool`

```sh
wtool uninstall all
wtool kill-self-forever
```

### `wtool install` 报「不是 git 仓库」

```sh
wtool install <项目> --force
```

### 项目里是 `output/` 而不是 `__output/`

```sh
cd <项目目录> && mv output __output && mv release __release && mv layer __layer
```

### `install.sh` 装包时看起来卡住

每 5 秒会打印一行进度：`wtool-install: 还在装…（30 秒） · Get:3 … 45.2 MB/120 MB`。有这行就还在跑。
