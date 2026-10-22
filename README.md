# wtool 使用说明书

> **一句话**：`wtool` 是把你的一堆零散配置（shell、终端、编辑器、常用命令行工具）
> 装到一台机器上、并且**装过什么、装在哪、怎么撤**都说得清的一套东西。
>
> - 只想**下载 / 在一台没有 `git` 的机器上装** → [`download.md`](download.md)
> - 每条命令的参数细节 → [`guide.md`](guide.md)
> - 为什么这么设计（软链、账本、产物分层、发布契约）→ [`原理.md`](原理.md)

这份文件是**说明书**：先把名词认全，再按"你在哪种机器上"和"你要装哪类项目"两条线
各走一遍。**不需要任何背景知识**，出现的名词第一次都会解释。

---

## 1. 先认名词

| 名词 | 一句话解释 |
|---|---|
| **wtool** | 你敲的那条命令。它自己也是一个项目（`wtool-base-tools`），住在你的机器上 |
| **项目** | 一个目录，里面有份 `wtool.xml`。**有它就是 wtool 项目**；没有就是普通文件，wtool 不管 |
| **工作区** | 所有项目并排放的那个目录（叫什么由你定）。**工作区根目录本身不是 Git 仓库**，它只是项目们拼在一起的地方 |
| **`$WTOOL_HOME`** | wtool 全部家当所在的那个目录，**默认 `~/.wtool`**。装的东西、记的账、导出的命令都在它里面；删掉它 = 这台机器上 wtool 的东西全没了 |
| **装（install）** | 让某个项目的文件"生效"：接进 `$WTOOL_HOME`、必要时生成 shell 集成。**不要 root、不联网** |
| **系统层（`sudo-…`）** | 装系统软件包、改 `/etc` 下文件这类**要 root、要联网**的动作。名字里带 `sudo-` 的才会要 root |
| **产物** | 项目"跑起来需要的那部分文件"。纯配置项目的产物就是它自己的配置文件；工具类项目的产物是编出来 / 下载来的可执行文件 |
| **发布页** | GitHub 上某个仓库的 Releases 页面。包（产物 + 校验文件）放在那儿，别人从那儿下 |

> **两条铁律**（记住这两条，其余都是细节）：
> ① **名字里带 `sudo-` 的才要 root、才联网**；不带的一律不要 root、永不联网。
> ② 装的东西都在 `$WTOOL_HOME` 里；想撤销就用 `wtool uninstall`，**不要 `rm -rf`**。

---

## 2. 两种环境：先确定你在哪一边

同一套东西，**有源码的机器**和**什么都没有的机器**走的是两条路。

### 2.1 开发机（有网络、能拿到源码）

能 `git clone`、能联网的机器。这条路的好处是**随时更新、随时改**。

```bash
# 0. 先有 git 和 python3（大多数发行版自带 python3）；repo 是个 Python 脚本，
#    很多发行版有包：sudo apt install repo
# 1. 把仓库们一次拉到本地（第一次）—— 清单在 w_manifests 仓的 wtool 分支
mkdir -p ~/self/wtool && cd ~/self/wtool
repo init -u https://github.com/allinkernel/w_manifests.git -b wtool
repo sync -j8
# 2. 装 wtool 自己 —— 它会把运行环境准备好，然后停下
./install.sh
# 3. 让当前 shell 认识 wtool（PATH 是 shell 启动时定下的）
exec $SHELL          # 或者重开一个终端
# 4. 系统层：系统软件包 + /etc 下的文件（要 root、要联网）
wtool sudo-bootstrap
# 5. 用户层：文件、链接、shell 集成（不要 root、不联网）
wtool bootstrap
```

没有 root 的机器（公司电脑很常见）**跳过第 4 步**，其余照样成立。

装完是什么样：`wtool` 能用、`wtool check` 说"一切对得上"、你的 `~/.zshrc` / `~/.bashrc`
**末尾多了两行**（`export WTOOL_HOME=…` + `source …/env.zsh`）。就这两行 —— wtool
不会在你的 `$HOME` 里到处建软链。

**日常更新**：在项目目录里 `git pull`，然后 `wtool install <项目>` 重装一次
（只重装改过的那个就行）。整批更新：`wtool bootstrap`。

### 2.2 断网机（没有网络，或者只有浏览器）

目标机器上**什么都不需要先有**（不需要 wtool、不需要 git、不需要 python3）。两条子路：

**(a) 整机迁移包**（推荐：把一台装好的机器整体搬过去）

按发行版各有一份，链接在[第 6 节](#6-下载页与发布页)。用法：

```bash
# 1. 拼回整包（包没分卷就跳过这行）
cat wtool-all-*.tar.gz.part-* > wtool-all.tar.gz
# 2. 解开 —— 得到的是一个名为 .wtool 的目录
tar xf wtool-all.tar.gz
# 3. 跑到新位置（想放在别处就换个目标，比如 ~/wangshaowei/.wtool）
mv .wtool ~/.wtool && cd ~/.wtool
# 4. 跑安装器：它只让 `wtool` 命令能用（**自动**往 ~/.bashrc / ~/.zshrc 末尾写那两行、
#    建入口链、自检），**不装任何项目**、**不碰 ~/.zshenv**
./install.sh
```

> 那两行是**自动写**的（不用回答问题）：只追加在文件末尾、已经在就不重复写、
> 原有内容一个字不动；rc 不存在就直接建。放进别处时用 `./install.sh --portable`，
> 那样**一个字节都不碰**你的 `~/.bashrc`，改成生成 `wtool-bashrc` / `wtool-zshrc`
> 让你自己 `source`。

> **2026-10-22 起包里是一份"还没装任何项目"的 `.wtool`**（上一版是"已经装好的"）。
> 所以多一步 —— 重新开一个终端，然后：

```bash
wtool            # 看清点：每个项目都是「未安装」
wtool bootstrap  # 一口气装好全部（离线，用包里自带的产物；不 sudo、不联网）
wtool check      # 一切对得上
```

装完 `zsh` 起来就是 oh-my-zsh 的提示符（`ZSH_THEME=ys`）。**`~/.zshenv` 不会被创建**：
zsh 的模块路径放在 `.wtool/.zshenv` 里，靠 `env.zsh` 导出的 `ZDOTDIR` 生效。

> 包里那份 `zsh` 是**按发行版编的**，所以整机包按发行版分三种（22.04 / 24.04 / 26.04）——
> **下和你目标机器同一个发行版的那份**。怎么查：`grep VERSION_ID /etc/os-release`。
> 22.04 那份要求最低（只要能跑 22.04 的机器都能跑）。

**(b) 单个项目的自足包**（已经有一份 `$WTOOL_HOME`，只缺某个项目）

从那个项目的发布页下 `source-offline.zip`（纯配置项目）或 `release-offline.zip`
（工具类项目），然后：

```bash
unzip -q source-offline.zip -d /tmp/new        # 工具类项目换成 release-offline.zip
cp -a /tmp/new/wtool/. "$WTOOL_HOME/wtool/"    # 同名合并
wtool install <项目路径>                        # 装它
```

**升级**同一个项目时，顺序不能变：

```bash
wtool uninstall <项目路径>                      # ① 先撤掉它建的链接和账
rm -rf "$WTOOL_HOME/wtool/<项目路径>"           # ② 再删旧的项目目录
unzip -q release-offline.zip -d /tmp/new       # ③ 解开新包
cp -a /tmp/new/wtool/. "$WTOOL_HOME/wtool/"    # ④ 同名合并
wtool install <项目路径>                        # ⑤ 重新装
```

> 第 ② 步的 `rm -rf` **必须手工做**：`wtool uninstall` 只撤它自己建的链接和账，
> **不会删** `$WTOOL_HOME/wtool/<项目路径>` 里的文件 —— 那些是从包里合并进来的，
> 不删就会新旧文件混在一起。

### 2.3 两种环境对照

| 你想干什么 | 开发机（有源码） | 断网机（只有包） |
|---|---|---|
| 第一次装 | `./install.sh` → `sudo-bootstrap` → `bootstrap` | 整机包：`tar xf` + `./install.sh`；单项目：`unzip` + `cp -a` + `wtool install` |
| 装一个项目 | `wtool install <项目>` | 同上（单项目那条） |
| 升级一个项目 | `git pull` + `wtool install <项目>` | 换成新的自足包，按 2.2(b) 那五步 |
| 升级全部 | `wtool bootstrap` | 换一版整机包，重走一遍 2.2(a) |
| 撤销一个项目 | `wtool uninstall <项目路径>` | 同左 |
| 看状态 | `wtool`（项目表）/ `wtool check`（对账） | 同左 |
| 打包发布 | `wtool pack-release` / `wtool pack-offline-release` → `wtool publish-…` | **用不到**（断网机上只剩 `install`） |

---

## 3. 三种项目：装法、升级、产物

每个项目在 `wtool.xml` 里声明自己属于哪一种。**类型决定三件事**：产物从哪来、
能不能自己编、发布什么包。

### 3.1 ① 纯配置项目（`kind="source"`）

**是什么**：仓库里就是最终要用的东西 —— 配置文件、脚本。典型：`terminal/tmux`
（tmux 配置）、`shell/shell-rc`（shell 配置）、`wtool-base-tools`（引擎自己）。

| | |
|---|---|
| 产物从哪来 | **不需要产物**，源码就是产物（所以没有"构建"这一步） |
| 怎么装 | 开发机：`wtool install terminal/tmux`；断网机：下 `source-offline.zip`，解压合并再 `wtool install` |
| 怎么升级 | 开发机：`git pull` + `wtool install <项目>`；断网机：换新包，按 2.2(b) 五步 |
| 产物包叫什么 | **`source-offline.zip`**（自足包，给断网机）。开发机不需要产物包 |
| 能跑哪些命令 | `install` / `uninstall` / `pack-offline-release` / `publish-offline-release`；**`build` / `pack-release` / `download-release` / `unpack-release` 对它没有意义**（敲了会被当场拒绝，并告诉你该用哪条） |

### 3.2 ② 上游二进制项目（`kind="muslbin"`）

**是什么**：不自己编，直接把**上游发布页**的现成二进制拿来当命令用（挑的是静态链接的，
不依赖你机器上的库）。典型：`tools/musl-bins/` 下的那些工具（`fzf`、`bat`、`jq` 这一类）。

| | |
|---|---|
| 产物从哪来 | `wtool download-release <项目>` 从**上游**发布页下（按 `wtool.xml` 里钉死的版本号和 sha256 校验）→ `wtool unpack-release <项目>` 解到项目的产物目录 |
| 怎么装 | 开发机：上面两步 + `wtool install <项目>`；断网机：下 `release-offline.zip`，解压合并再 `wtool install` |
| 怎么升级 | 改 `wtool.xml` 里的版本号（+ 新的 sha256）→ 重新 download / unpack / install。**或者**直接用我们发的自足包 |
| 产物包叫什么 | **`release-offline.zip`**（自足包，给断网机：二进制 + 声明 + shell 集成） |
| 能跑哪些命令 | `download-release` / `unpack-release` / `install` / `uninstall` / `pack-offline-release` / `publish-offline-release`；**不自己 `build`**，也不发 `release.zip`（产物是上游的，不是我们编的） |

> 这类项目**升级就是换版本号 + 换 sha256**，两行改动；改完在开发机上重跑那三条命令。

### 3.3 ③ 容器构建项目（`kind="docker"`）

**是什么**：产物要**自己编**，而且要在**容器里编** —— 因为"给哪个发行版用"这件事
只有编的时候能定。典型：`shell/zsh`（zsh 的源码，按发行版各编一份）。

| | |
|---|---|
| 产物从哪来 | `wtool build <项目>`（要 docker）：引擎按项目里的目标清单逐个发行版起容器编，产物导到项目的产物目录 |
| 怎么装 | 开发机：`wtool build` → `wtool install <项目>`；断网机：下**整机包**（推荐），或 `release-offline.zip` |
| 怎么升级 | 开发机：`git pull` → `wtool build <项目>` → `wtool install <项目>`；断网机：换整机包 |
| 产物包叫什么 | **两个族都有**：`release.zip`（只有产物 + 一份 `dist.json` 校验清单，给**有源码的开发机**：`download-release` → `unpack-release` → `install`）；**`release-offline.zip`**（自足包，给断网机） |
| 能跑哪些命令 | 三类里最全：`build` / `install` / `uninstall` / `pack-release` / `publish-release` / `download-release` / `unpack-release` / `pack-offline-release` / `publish-offline-release`，以及容器层那几条（`unpack-layer` / `push-layer` / `pull-layer`） |

> ⚠️ **这类项目的产物和发行版绑在一起**（编的时候链接了那个发行版的系统库）。
> 所以整机包按发行版分三份；`release-offline.zip` 也请认准发行版。

---

## 4. 总表

**命令 × 项目类型**（✅ = 能跑；— = 对它没有意义，敲了会被拒绝并指路）：

| 命令 | ① `source` | ② `muslbin` | ③ `docker` | 这条命令是干什么的 |
|---|:--:|:--:|:--:|---|
| `wtool install <项目>` | ✅ | ✅ | ✅ | 装（不要 root、不联网） |
| `wtool uninstall <项目路径>` | ✅ | ✅ | ✅ | 撤（只撤 wtool 建的东西） |
| `wtool build <项目>` | — | — | ✅ | 编产物（③ 要 docker；② 的产物从上游下） |
| `wtool download-release <项目>` | — | ✅ | ✅ | 从发布页下现成的包到项目里 |
| `wtool unpack-release <项目>` | — | ✅ | ✅ | 校验 + 解开，写进项目的产物目录 |
| `wtool pack-release <项目>` | — | — | ✅ | 打**开发机用**的产物包（`release.zip` + `dist.json`） |
| `wtool publish-release <项目>` | — | — | ✅ | 把上面的包传到发布页（只上传） |
| `wtool pack-offline-release <项目>` | ✅ | ✅ | ✅ | 打**断网机用**的自足包 |
| `wtool publish-offline-release <项目>` | ✅ | ✅ | ✅ | 把自足包传到**离线**那一页 |
| `wtool sudo-install <项目>` | 少数（`os/ubuntu` 这种） | — | — | 系统层：系统软件包 + `/etc`（要 root） |

**包 × 谁用**：

| 包 | 里面是什么 | 给谁 |
|---|---|---|
| `source-offline.zip` | ① 项目的源码 + 声明 | 断网机（合并进已有 `$WTOOL_HOME`） |
| `release-offline.zip` | ②③ 项目的产物 + 声明 + shell 集成 | 断网机（合并进已有 `$WTOOL_HOME`） |
| `release.zip` + `dist.json` | ③ 项目**只有产物** | **有源码的开发机**（`download-release` → `unpack-release`） |
| `wtool-base-tools.tar.gz` | **一个 `$WTOOL_HOME` 的种子**（引擎 + 入口） | 还没有 `$WTOOL_HOME` 的机器（安装器包） |
| `wtool-all-ubuntu<版本>.tar.gz` | **整台机器**：所有可发布项目的源码 + 产物（**没有** `usr/`、没有账本 —— 是一份"**还没装**"的 `.wtool`） | 换机器 / 断网机（`tar xf` + `./install.sh` + `wtool bootstrap`） |
| `<包名>.sha256` | 一行 sha256 | 校验：`sha256sum -c <包名>.sha256` |
| `check-hash*.sh`（分卷时才有） | 每个分卷的 sha256 写全 | 校验：`sh check-hash*.sh`（**不需要 wtool**） |

---

## 5. 一分钟开箱

**开发机**

```bash
./install.sh                 # 装 wtool 自己（会先把运行环境准备好）
exec $SHELL                  # 让 shell 认识 wtool
wtool                        # 看项目表：每个项目支持什么、走到哪一步
wtool sudo-bootstrap         # 系统层（要 root；没有 sudo 就跳过）
wtool bootstrap              # 用户层：把所有项目装上
wtool check                  # 对账：声明 / 账本 / 磁盘三者一致
```

**断网机**

```bash
cat wtool-all-*.tar.gz.part-* > wtool-all.tar.gz   # 分卷才需要
tar xf wtool-all.tar.gz                            # → 得到一个 .wtool 目录
cd .wtool && ./install.sh                          # 接到位
exec $SHELL && wtool check                         # 验收：应当说"一切对得上"
```

---

## 6. 下载页与发布页

**下载入口**：[`download.md`](download.md) —— 那张表由引擎自动查 GitHub 重写，
里面的链接都是线上真实存在的地址。

**整机迁移包**（把一台装好的机器整体搬走用；三种发行版各一份）：

| 目标机器 | 下哪个 | 大小 | sha256（`sha256sum -c` 用同名 `.sha256`） | 包里 zsh 要求的最低 glibc |
|---|---|---|---|---|
| Ubuntu 22.04 | [`wtool-all-ubuntu22.04.tar.gz`](https://github.com/allinkernel/wtool-doc/releases/download/offline-2026-10-22-r2/wtool-all-ubuntu22.04.tar.gz) | 213,965,298 B | `323690482702e195b9f610cb8010f174e4c33d2688b96e6e3ef1ec4ee92abd6e` | 2.34 |
| Ubuntu 24.04 | [`wtool-all-ubuntu24.04.tar.gz`](https://github.com/allinkernel/wtool-doc/releases/download/offline-2026-10-22-r2/wtool-all-ubuntu24.04.tar.gz) | 213,965,329 B | `cce5a320df5b4b3505a29f83794d8b953f9c1cf900e1a8159d5448779145c337` | 2.38 |
| Ubuntu 26.04 | [`wtool-all-ubuntu26.04.tar.gz`](https://github.com/allinkernel/wtool-doc/releases/download/offline-2026-10-22-r2/wtool-all-ubuntu26.04.tar.gz) | 213,965,314 B | `68d2d14bc864963c8cbba99e8e812131e9777f32f49c3e995872fe75c41d374f` | 2.38 |

发布页（旁边有 `.sha256`，分卷时还会有 `check-hash*.sh`）：
<https://github.com/allinkernel/wtool-doc/releases/tag/offline-2026-10-22-r2>

> ⚠️ 上表是 **`offline-2026-10-22-r2`** 那一版 —— 包 = 一份"**还没装任何项目**"的 `.wtool`
> （没有 `usr/`、没有 `var/`、没有 L1 链）。解开来 `wtool` 列出的全是「未安装」，
> `wtool bootstrap` 才装起来。用法见上面 §2.2(a)。
> 上一版 **`offline-2026-10-21`** 的包是"已经装好的"，**两版用法不一样，别混着用**。

> #### 这一版（`offline-2026-10-22-r2`）的内容
>
> **整机包 = 工作区里所有"可发布"的项目**（不是"打包那台机器装过的项目"）：
> **43 个** `tools/musl-bins/*`（2026-10-22 按用户口径**删掉了 `atuin`**：不装、不生成
> shell 集成、不绑键；历史搜索改成 **bash 的 Ctrl-P = fzf**，zsh 的 Up 恢复原生
> `up-line-or-history`，zsh 的 ^R 保持 fzf 默认），外加 `shell/zsh`
> （**22.04 / 24.04 / 26.04 三套都在包里**，装机时按你的发行版自动挑）、
> `os/ubuntu`、`wtool-base-tools`、`shell/shell-rc`、`shell/oh-my-zsh`、
> `terminal/tmux`、`terminal/fzf`、`tools/git-repo-sh-tools`、`tools/android_repack`。
> **不含** `dsh-conf` / `dsh-remote`（它们声明了 `<publish kind="none"/>`）。
>
> 所以包大约 **204 MB / 一份整包（不分卷）** —— 直接从发布页下
> `wtool-all-ubuntu<版本>.tar.gz`，旁边就是 `.sha256`（`sha256sum -c` 过一遍再用）。
>
> **三份包的内容是一样的**（同一份源码 + 同一个打包动作 → 逐字节相同的产物），
> 只有资产名和 zsh 那套"默认挑哪个发行版"的起始值不同 —— 装机时
> `install.sh` 会按 `/etc/os-release` 把你本机那套 zsh 选出来。

> **22.04 那份要求最低**（2.34）：能跑 22.04 的机器都能跑它。
> 24.04 / 26.04 两份要求一样（2.38）—— 26.04 那份是"在本发行版里编的"，
> 追求的是原生；机器新、想省事的话下 24.04 那份也能在 26.04 上跑。

> #### 借用别人的机器？（`--portable`）
>
> 如果这台机器不是你的（`~/.bashrc` 动不得），把包解到**你自己的目录**下再装：
>
> ```bash
> mkdir -p ~/你的名字 && cd ~/你的名字
> cat ~/下载的/wtool-all-ubuntu24.04.tar.gz.part-* > wtool-all.tar.gz && tar xf wtool-all.tar.gz
> cd .wtool && ./install.sh --portable          # 自动检测到"这不是我的家目录"
> source ~/你的名字/wtool-bashrc                # 以后每次开 shell 手动 source 这一行
> ```
>
> `--portable`（或用 `--prefix ~/你的名字`）**一个字节都不碰** `~/.bashrc` /
> `~/.zshrc`，而是在 `~/你的名字/` 下生成 `wtool-bashrc` 与 `wtool-zshrc`。
> 检测依据会打印出来（`$HOME` 属主不是当前用户 / rc 不可写 / 家在共享挂载上 /
> `$WTOOL_HOME` 不在 `$HOME/.wtool`）—— 不会静默切换。

**各项目的离线自足包**（`offline-…` 那一族；点进去就能下，旁边有 `.sha256` 校验）：

| 项目 | 离线包 | 发布页 |
|---|---|---|
| `wtool-base-tools`（安装器种子包） | `wtool-base-tools.tar.gz` | <https://github.com/allinkernel/wtool-base-tools/releases/tag/offline-2026-10-22-r2> |
| `shell/zsh`（按发行版编的 zsh） | `release-offline.zip` | <https://github.com/allinkernel/wtool-zsh/releases/tag/offline-2026-10-22-r2> |
| `tools/musl-bins/*`（上游二进制工具，**一个仓库多个项目**） | **`<工具名>-release-offline.zip`**（例：`bat-release-offline.zip`、`jq-release-offline.zip`） | <https://github.com/allinkernel/wtool-musl-bins/releases/tag/offline-2026-10-22-r2> |
| `shell/shell-rc` | `source-offline.zip` | <https://github.com/allinkernel/wtool-shell-rc/releases/tag/offline-2026-10-22-r2> |
| `shell/oh-my-zsh` | `source-offline.zip` | <https://github.com/allinkernel/wtool-ohmyzsh/releases/tag/offline-2026-10-22-r2> |
| `terminal/tmux` | `source-offline.zip` | <https://github.com/allinkernel/wtool-tmux-config/releases/tag/offline-2026-10-22-r2> |
| `terminal/fzf` | `source-offline.zip` | <https://github.com/allinkernel/wtool-fzf-binary/releases/tag/offline-2026-10-22-r2> |
| `tools/git-repo-sh-tools` | `source-offline.zip` | <https://github.com/allinkernel/wtool-repo/releases/tag/offline-2026-10-22-r2> |
| `tools/android_repack` | `source-offline.zip` | <https://github.com/allinkernel/wtool-android_repack/releases/tag/offline-2026-10-22-r2> |
| `os/ubuntu` | `source-offline.zip` | <https://github.com/allinkernel/wtool-os-ubuntu/releases/tag/offline-2026-10-22-r2> |

> `dsh-projects/dsh-conf` / `dsh-projects/dsh-remote` 声明了 `<publish kind="none"/>`
> （不参与发布）—— 它们**没有**离线自足包，不要在这一族里找它们。

`ds_dev-…` 那一族（给有源码的开发机）也有，例如
`shell/zsh` 的 <https://github.com/allinkernel/wtool-zsh/releases/tag/ds_dev-2026-10-14>。

**各个项目自己的发布页**（要找某个项目的包就点进去）：

| 项目 | 仓库 / 发布页 |
|---|---|
| `wtool-base-tools`（引擎 + 安装器包） | <https://github.com/allinkernel/wtool-base-tools/releases> |
| `shell/zsh`（zsh 源码，按发行版编） | <https://github.com/allinkernel/wtool-zsh/releases> |
| `shell/shell-rc` | <https://github.com/allinkernel/wtool-shell-rc/releases> |
| `shell/oh-my-zsh` | <https://github.com/allinkernel/wtool-ohmyzsh/releases> |
| `terminal/tmux` | <https://github.com/allinkernel/wtool-tmux-config/releases> |
| `terminal/fzf` | <https://github.com/allinkernel/wtool-fzf-binary/releases> |
| `tools/musl-bins/*`（上游二进制工具，一个仓库多个项目） | <https://github.com/allinkernel/wtool-musl-bins/releases> |
| `tools/git-repo-sh-tools` | <https://github.com/allinkernel/wtool-repo/releases> |
| `tools/android_repack` | <https://github.com/allinkernel/wtool-android_repack/releases> |
| `dsh-projects/dsh-remote` | <https://github.com/allinkernel/wtool-dsh-remote/releases> |
| `os/ubuntu` | <https://github.com/allinkernel/wtool-os-ubuntu/releases> |
| 这份文档（`wtool-doc`） | <https://github.com/allinkernel/wtool-doc/releases> |

**两类 tag 一眼分**：

| tag 长什么样 | 里面是什么 | 给谁 |
|---|---|---|
| `ds_dev-…` / `snapshot-…` | **开发机那一族**：产物包 + `dist.json` | 有源码的机器（`wtool download-release`） |
| **`offline-…`** | **离线那一族**：自足包 + `.sha256`（分卷时还有 `check-hash*.sh`） | 断网机（手动下载） |

---

## 7. 常见问题

**Q：装完敲 `wtool` 说 command not found？**
A：`PATH` 是 shell 启动时定下的。按 2.1 节第 3 步做：`exec $SHELL` 或重开终端。
还不行就 `wtool doctor`（它会把该有的环境变量打出来）。

**Q：`wtool check` 说"对不上"，怎么办？**
A：看它报的是哪一类：
- "链接/文件缺了" → `wtool repair <项目>`（只重建，不删）
- "项目不在磁盘上了（改过名？）" → `wtool uninstall <旧路径> --no-script`
- 整机包刚解开、还没接线 → 在 `.wtool` 里跑一次 `./install.sh`

**Q：能直接把 `$WTOOL_HOME` 删掉吗？**
A：那等于"这台机器上 wtool 装的东西全没了"，而你的 rc 里那两行还指着它。
想干净卸载用 `wtool kill-self-forever`（不可逆）；或者先 `wtool uninstall all`，
再删那个目录和 rc 里那两行。

**Q：为什么断网机的包还分发行版？**
A：因为工具类项目的产物是**编**出来的，编的时候链接了那个发行版的系统库。
拿新发行版编的去老发行版上跑会报 `GLIBC_x.xx not found`。所以按发行版下对应的包。

**Q：为什么 `tools/musl-bins` 那批包叫 `bat-release-offline.zip`，别的项目就叫 `release-offline.zip`？**
A：**一个仓库多个项目**时名字带项目名。`tools/musl-bins` 是 42 个工具住在**同一个仓库**、
共用**同一个发布页** —— 名字要是不带工具名，42 个同名文件会互相覆盖，页面上只会剩最后一个。
所以那一族是 `<工具名>-release-offline.zip`（一页 42 个包，想要哪个下哪个）；
一个仓库一个项目的（`shell/zsh`、`terminal/tmux`…）名字不变。

**Q：三种发行版的整机包怎么选？22.04 那份能在 24.04 上跑吗？**
A：**按目标机器选同一发行版的最稳**，但要记住三条：
- **22.04 那份要求最低**（只要 `GLIBC_2.34`）→ **能跑 22.04 的机器都能跑它**，拿不准就下这份；
- **24.04 那份在 26.04 上也能跑**（两份都只要求 `GLIBC_2.38`），所以 26.04 的机器图省事
  可以先用 24.04 那份；26.04 那份是"在 26.04 里编的"，追求原生就用它；
- 反过来**不行**：24.04/26.04 那份拿到 22.04 上会报 `GLIBC_2.38 not found`。

**Q：`source-offline.zip` 和 `release-offline.zip` 有什么区别？**
A：前者是纯配置项目（①）的自足包，后者是工具类项目（②③）的自足包 ——
里面都带"离线机上 `wtool install` 需要的东西"，只是产物那一部分一个有、一个没有。

**Q：包怎么校验？**
A：单包：`sha256sum -c <包名>.sha256`；分卷：`sh check-hash*.sh`
（脚本里写全了每一卷的 sha256，**不需要 wtool**）。两者都会明确告诉你哪一卷坏了。

---

## 8. 还想知道更多

| 想知道 | 看 |
|---|---|
| 每条命令的所有参数 | [`guide.md`](guide.md) |
| 为什么这么设计（链接、账本、产物分层、发布契约） | [`原理.md`](原理.md) |
| 下载 / 离线安装（不用 `git`） | [`download.md`](download.md) |
| 现在有哪些项目、各自什么类型 | 敲 `wtool`（不带参数，就是那张表） |
| 某个项目自己怎么编、怎么用 | 那个项目仓库里的 `README.md` |
