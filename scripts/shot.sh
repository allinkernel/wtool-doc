#!/bin/sh
# 把"跑一条命令的真实输出"渲染成文档用的终端截图。
#
#   scripts/shot.sh <输出名> [--shell zsh|bash] [--dir 项目目录] -- '<命令>'
#
# 产物：img/<输出名>.png（同时保留 /tmp/wtool-shot/<输出名>.ansi 原始转录）
# 依赖：script(1) + ImageMagick(pango) + scripts/term-shot.py
set -eu
[ $# -ge 2 ] || { echo "用法: shot.sh <名字> [--shell zsh|bash] [--dir 目录] -- '<命令>'" >&2; exit 2; }
name=$1; shift
shell=zsh; dir=.
while [ $# -gt 0 ]; do
    case $1 in
        --shell) shell=$2; shift 2 ;;
        --dir)   dir=$2;   shift 2 ;;
        --)      shift; break ;;
        *) break ;;
    esac
done
[ $# -ge 1 ] || { echo "缺少命令" >&2; exit 2; }
cmd=$1

root=$(cd -- "$(dirname -- "$0")/.." && pwd)
out=$root/img/$name.png
scratch=/tmp/wtool-shot
mkdir -p "$scratch" "$root/img"

# 干净的交互 shell + 我们自己的 env（不加载用户 rc，避免 oh-my-zsh 更新提示干扰）
if [ "$shell" = zsh ]; then
    inner="cd '$dir' && source \"\${WTOOL_HOME:-\$HOME/.wtool}/env.zsh\" && $cmd"
    run="env -i HOME=$HOME PATH=/usr/bin:/bin TERM=xterm-256color DISABLE_AUTO_UPDATE=true WTOOL_HOME=${WTOOL_HOME:-$HOME/.wtool} zsh -f -i -c \"$inner\""
else
    inner="cd '$dir' && source \"\${WTOOL_HOME:-\$HOME/.wtool}/env.bash\" && $cmd"
    run="env -i HOME=$HOME PATH=/usr/bin:/bin TERM=xterm-256color DISABLE_AUTO_UPDATE=true WTOOL_HOME=${WTOOL_HOME:-$HOME/.wtool} bash --norc --noprofile -i -c \"$inner\""
fi

# 先把命令行本身打出来（模拟用户敲的那一行），再跑
transcript=$scratch/$name.ansi
: > "$transcript"
printf '\033[32m❯\033[0m %s\r\n' "$cmd" >> "$transcript"
script -qec "$run" "$scratch/$name.body" >/dev/null 2>&1 || true
sed -e '/^Script started on/d' -e '/^Script done on/d' \
    -e 's/\x1b\]0;[^\x07]*\x07//g' -e 's/\x1b\]1;[^\x07]*\x07//g' \
    -e 's/\x1b\]2;[^\x07]*\x07//g' \
    "$scratch/$name.body" >> "$transcript" 2>/dev/null || true
rm -f "$scratch/$name.body"

python3 "$root/scripts/term-shot.py" "$transcript" "$out"

# 颜色判据：只数**命令输出**里的 SGR（第一行是我们自己画的绿色 ❯，不算）。
# 有 SGR 的命令必须是彩色图（%k > 100）；没有 SGR 的命令本身就不输出颜色。
sgr=$(tail -n +2 "$transcript" | grep -aoE "$(printf '\033\\[[0-9;]*m')" | wc -l | tr -d ' ')
colors=$(identify -format '%k' "$out" 2>/dev/null || echo 0)
colors=${colors:-0}
printf '%s\t%s\t%s\n' "$name" "$sgr" "$colors" >> "$scratch/colors.tsv"
if [ "$sgr" -gt 0 ] && [ "$colors" -le 100 ]; then
    echo "  颜色判据失败: $name（SGR $sgr 条，但 PNG 只有 $colors 色）" >&2
    exit 1
fi
if [ "$sgr" -eq 0 ]; then
    echo "  该命令本身不输出颜色（$name，PNG $colors 色）"
fi
echo "  截图: $out   （转录: $transcript，SGR $sgr，颜色 $colors）"
