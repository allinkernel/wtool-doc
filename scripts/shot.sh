#!/bin/sh
# 把"真交互 shell 里敲命令"的**整屏**渲染成文档用的终端截图。
#
#   scripts/shot.sh <输出名> [--shell zsh|bash] [--dir 起始目录] [--] '<命令>' ['<命令>' ...]
#
# 做法（2026-10-27 重做，对齐用户要求）：
#   ① 用 tmux 起一个**真终端**（pty + 终端模拟器），里面跑 **真交互 shell**：
#      zsh 读 ~/.zshrc → $WTOOL_HOME/env.zsh → oh-my-zsh（ys 主题），不是 `zsh -f`；
#   ② 命令用 `tmux send-keys -l` 当**键入**送进去（逐字符，不是 `-c` 执行）；
#   ③ 命令跑完（tty 前台进程组回到 shell 自己 + 屏幕稳定）后
#      `tmux capture-pane -p -e` 抓**整屏**（含彩色的 ys 提示符行）；
#   ④ 交给 term-shot.py 用 JetBrains Mono 渲染，宽 ≥1100px。
#
# 为什么不用 `script(1)`：script 抓的是**字节流水**，而提示符是异步重画的
# （oh-my-zsh 的 git 信息走 async handler → `zle reset-prompt`），流水里带重画和
# 光标回跳，直接渲染就是残影。tmux 本身就是终端模拟器，capture-pane 拿到的
# 就是"屏幕上现在是什么"。
#
# 产物：img/<名字>.png + /tmp/wtool-shot/<名字>.ansi（整屏原始捕获）
#       + /tmp/wtool-shot/<名字>.log（去掉颜色后的同屏文本，便于核对）
# 依赖：tmux、ImageMagick(pango)、scripts/term-shot.py
set -eu
[ $# -ge 2 ] || { echo "用法: shot.sh <名字> [--shell zsh|bash] [--dir 目录] [--] '<命令>' ..." >&2; exit 2; }
name=$1; shift
shell=zsh; dir=$PWD; cols=${SHOT_COLS:-200}; rows=${SHOT_ROWS:-120}; home=$HOME; wait_s=0
while [ $# -gt 0 ]; do
    case $1 in
        --shell) shell=$2; shift 2 ;;
        --dir)   dir=$2;   shift 2 ;;
        --home)  home=$2;  shift 2 ;;   # demo 家目录（干净的账本；见 scripts/make-shots.sh）
        --wait)  wait_s=$2; shift 2 ;;  # TUI：命令不会退出，固定等 N 秒再抓屏
        --cols)  cols=$2;  shift 2 ;;
        --rows)  rows=$2;  shift 2 ;;
        --)      shift; break ;;
        *) break ;;
    esac
done
[ $# -ge 1 ] || { echo "缺少命令" >&2; exit 2; }

root=$(cd -- "$(dirname -- "$0")/.." && pwd)
out=$root/img/$name.png
scratch=${WTOOL_SHOT_DIR:-/tmp/wtool-shot}
mkdir -p "$scratch" "$root/img"
cap=$scratch/$name.ansi
log=$scratch/$name.log
sock=wtool-shot-$$        # 每个进程一个 socket：两张图互不干扰（可以并行跑）

# 独立的 tmux server（私有 socket + 空配置）：不碰用户正在用的 tmux
tmux -L "$sock" kill-server 2>/dev/null || true

case $shell in
    zsh)  shbin=${SHOT_ZSH:-zsh} ;;
    bash) shbin=${SHOT_BASH:-bash} ;;
    *) echo "不认识的 shell: $shell" >&2; exit 2 ;;
esac

# DISABLE_AUTO_UPDATE：别让 oh-my-zsh 在截图时弹更新提示；
# HISTFILE：别把截图用的命令写进用户真实历史（提示符/主题/补全都还是真的）。
# --home：换一个"账本干净"的家目录（真交互 shell 读它是 $HOME/.zshrc，
#    所以给它写一份和文档一样的两行 rc；ys 提示符照样来自 oh-my-zsh）。
if [ "$home" != "$HOME" ]; then
    rcf=$home/.zshrc
    [ "$shell" = bash ] && rcf=$home/.bashrc
    if [ ! -f "$rcf" ]; then
        printf 'export WTOOL_HOME=~/.wtool\nsource ${WTOOL_HOME}/env.%s\n' "$shell" > "$rcf"
    fi
fi

# 家目录/环境必须在**启动 tmux server 那一层**给：tmux 用 `$SHELL -c` 起窗格，
# 外那层 shell 也会读 rc（不设 HOME 就会去读真 ~/.zshrc，demo 家里就多一行报错）。
# ZDOTDIR 也一起钉死：本会话环境里它有值（~/.wtool），不清掉 zsh 会绕过 $HOME/.zshrc。
# -u NO_COLOR：DSH 自己的 bash 环境里带 NO_COLOR=1，会泄漏进 tmux，让 bat / eza / rg / delta
#    这些工具全部不上色（真用户的 shell 里没有这个变量）。截图必须是带色的。
env -u NO_COLOR -u CLICOLOR -u CLICOLOR_FORCE -u ZDOTDIR \
    HOME="$home" ZDOTDIR="$home" WTOOL_HOME="$home/.wtool" \
    DISABLE_AUTO_UPDATE=true DISABLE_UPDATE_PROMPT=true HISTFILE="$scratch/.hist" \
    TERM=xterm-256color \
    tmux -L "$sock" -f /dev/null new-session -d -s shot -x "$cols" -y "$rows" -c "$dir" \
    "exec $shbin -i"

pane_pid=$(tmux -L "$sock" display-message -p -t shot '#{pane_pid}')
pane_tty=$(tmux -L "$sock" display-message -p -t shot '#{pane_tty}')
shell_pgid=$(ps -o pgid= -p "$pane_pid" | tr -d ' ')
ttyname=${pane_tty#/dev/}

tpgid() { ps -o tpgid= -t "$ttyname" 2>/dev/null | tr -d ' ' | sort -u | head -1; }

# 空闲 = tty 的前台进程组就是 shell 自己（命令跑完了）+ 屏幕 2 次采样没变（输出停了）
wait_idle() {
    prev=''; stable=0; n=0; idle=0
    while [ "$n" -lt 600 ]; do
        sleep 0.2; n=$((n + 1))
        cur=$(tmux -L "$sock" capture-pane -p -t shot 2>/dev/null || true)
        if [ -n "$cur" ] && [ "$cur" = "$prev" ]; then stable=$((stable + 1)); else stable=0; fi
        prev=$cur
        [ -n "$(tpgid)" ] && [ "$(tpgid)" = "$shell_pgid" ] && idle=1
        if [ "$idle" -eq 1 ] && [ "$stable" -ge 2 ]; then return 0; fi
    done
    return 0
}

# shell 初始化：等 rc 跑完 + 异步 git 提示符刷上去
wait_idle
sleep 0.6

for cmd in "$@"; do
    sleep 0.3
    tmux -L "$sock" send-keys -t shot -l -- "$cmd"
    tmux -L "$sock" send-keys -t shot Enter
    if [ "$wait_s" -gt 0 ]; then
        sleep "$wait_s"          # TUI（btm / lazygit / yazi …）不会退出，等它画完就抓
    else
        wait_idle
        sleep 0.4
    fi
done

tmux -L "$sock" capture-pane -p -e -t shot > "$cap"
tmux -L "$sock" kill-server 2>/dev/null || true

python3 "$root/scripts/term-shot.py" "$cap" "$out" >/dev/null

sgr=$(grep -aoE "$(printf '\033\\[[0-9;]*m')" "$cap" 2>/dev/null | wc -l | tr -d ' ')
{
    echo "== $name  ($shell @ $dir)"
    echo "-- commands: $*"
    sed 's/\x1b\[[0-9;]*m//g' "$cap" | sed -e 's/[[:space:]]*$//' -e '/^$/d'
} > "$log"

w=$(identify -format '%w' "$out"); h=$(identify -format '%h' "$out")
kb=$(( $(wc -c < "$out") / 1024 ))
printf '%s\t%sx%s\t%sKB\tSGR %s\n' "$name" "$w" "$h" "$kb" "$sgr"
