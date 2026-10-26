# dsh 命令

这些命令来自 `wtool-doc` 工作区里的 `dsh-projects/*`（`dsh-remote` / `dsh-notify` 等），
**不在整机包里** —— 只有你装了对应项目（`wtool install dsh-projects/dsh-remote` 之类）
才在 `$WTOOL_HOME/usr/bin` 里出现。工具与环境的命令见 [tutorial.md](tutorial.md)。

## 手机远程

### dsh-remote

**功能**：手机远程查看 / 接管这台机器上的 DSH 会话（体检、隧道、常驻服务、推送、密码）。

**常用**：

```sh
dsh-remote status              # 体检：harness / 隧道 / 推送 / 手机地址
dsh-remote url                 # 打印手机能打开的地址
dsh-remote serve-install       # 把 dsh web 装成常驻服务
dsh-remote tunnel-install      # 装反向隧道
dsh-remote passwd              # 改中继密码
```

**提示**：云上那半用 `dsh-remote server`（或 `cloud-install`）；`--help` 里是全量清单。

![dsh-remote --help](img/dsh-remote-help.png)

### dsh-remote-server

**功能**：`dsh-remote server` 的别名 —— 一条命令装好云上 + 家里两侧。

**常用**：

```sh
dsh-remote-server              # 等同 dsh-remote server，参数原样传给它
```

![dsh-remote-server --help](img/dsh-remote-server-help.png)

### dsh-token-broker

**功能**：把手机访问的 `/` 302 到当前 `dsh web` 的 token 地址，省得手输 token。

**常用**：

```sh
dsh-token-broker                       # 默认 127.0.0.1:3081 → 3080
dsh-token-broker --port 4081 --web-port 3080
dsh-token-broker --token-file ~/.dsh/web-token
```

**提示**：`broker-install` / `broker-uninstall`（`dsh-remote`）负责把它装成常驻服务。

![dsh-token-broker --help](img/dsh-token-broker-help.png)

## 推送

### dsh-notify

**功能**：把一条消息推到手机（Graph / 邮件等 provider）。

**常用**：

```sh
dsh-notify --test                    # 推一条测试消息
dsh-notify --test --provider graph   # 只测 Graph 这条通道
dsh-notify "标题" "正文"              # 直接推
some-hook | dsh-notify --hook         # 从 stdin 读 hook JSON
```

![dsh-notify --help](img/dsh-notify-help.png)

### dsh-notify-graph-setup

**功能**：一次性授权 Microsoft Graph，把结果写进 `notify.conf`。

**常用**：

```sh
dsh-notify-graph-setup         # 按提示在浏览器里授权一次
```

![dsh-notify-graph-setup --help](img/dsh-notify-graph-setup-help.png)

### dsh-qr

**功能**：把一段文本（比如手机地址）画成终端二维码。

**常用**：

```sh
dsh-remote url | dsh-qr        # 手机扫一下就打开
dsh-qr 'https://example.com'
```

![dsh-qr --help](img/dsh-qr-help.png)

## 常驻 / 运维

### dsh-web-run

**功能**：`dsh web` 的常驻包装（给 systemd 用），自动带 token。

**常用**：

```sh
dsh-web-run                    # 前台跑（systemd 里用它当 ExecStart）
```

![dsh-web-run --help](img/dsh-web-run-help.png)

### harness-remote

**功能**：云上那半的管理器：隧道 / token broker / 公网入口。

**常用**：

```sh
harness-remote status
harness-remote restart
```

![harness-remote --help](img/harness-remote-help.png)

### dsh-force-restart-dsh-remote

**功能**：`dsh-remote force-restart-dsh-remote` 的薄封装：重启隧道和 broker，再复验一遍。

**常用**：

```sh
dsh-force-restart-dsh-remote
```

![dsh-force-restart-dsh-remote --help](img/dsh-force-restart-help.png)
