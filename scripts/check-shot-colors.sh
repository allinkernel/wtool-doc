#!/bin/sh
# 逐张检查 img/*.png 的截图质量（2026-10-27 换的新判据）。
#
#   sh scripts/check-shot-colors.sh [--report 文件.tsv]
#
# 每张图必须同时满足：
#   ① 宽 ≥ 1100px（分辨率不能太低）；
#   ② 单张 < 300KB（文档仓库不该塞大图）；
#   ③ 整屏捕获里有 SGR（ANSI 颜色）—— 提示符本身是彩色的，一个颜色都没有说明渲染丢了色；
#   ④ 有真提示符：zsh 的 ys 提示符行（`# user @ host in dir … [HH:MM:SS]`）
#      或 bash 的 `user@host:dir$`（TUI/异常场景会在这里露出来）；
#   ⑤ 有对应捕获 /tmp/wtool-shot/<名字>.ansi（能复查是哪一屏）。
#
# 退出码：0 = 全部通过；1 = 有不合格的。
set -eu
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
scratch=${WTOOL_SHOT_DIR:-/tmp/wtool-shot}
report=''
[ "${1:-}" = --report ] && { report=$2; shift 2; }
[ -n "$report" ] && : > "$report"

min_w=${SHOT_MIN_WIDTH:-1100}
max_kb=300
bad=0
printf 'name\t尺寸\t大小\tSGR\t提示符\n' >&2
for png in "$root"/img/*.png; do
    name=${png##*/}; name=${name%.png}
    ansi=$scratch/$name.ansi
    w=$(identify -format '%w' "$png" 2>/dev/null || echo 0)
    h=$(identify -format '%h' "$png" 2>/dev/null || echo 0)
    kb=$(( $(wc -c < "$png") / 1024 ))
    sgr=0; prompt=no
    if [ -f "$ansi" ]; then
        sgr=$(grep -aoE "$(printf '\033\\[[0-9;]*m')" "$ansi" | wc -l | tr -d ' ')
        # zsh(ys)：`# user @ host in dir … [12:34:56]`；bash：`user@host:dir$`
        if sed 's/\x1b\[[0-9;]*m//g' "$ansi" |
            grep -qE '(@[^@]* in .*\[[0-9]+:[0-9]+:[0-9]+\]|[a-z0-9_.-]+@[a-z0-9_.-]+:[^ ].*[$#] *$)'; then
            prompt=yes
        fi
    fi
    printf '%s\t%sx%s\t%sKB\t%s\t%s\n' "$name" "$w" "$h" "$kb" "$sgr" "$prompt" >&2
    [ -n "$report" ] && printf '%s\t%dx%d\t%s\n' "$name" "$w" "$h" "$kb" >> "$report"
    if [ "$w" -lt "$min_w" ]; then
        echo "  不合格: $name 宽 ${w}px < ${min_w}px" >&2; bad=1
    fi
    if [ "$kb" -ge "$max_kb" ]; then
        echo "  不合格: $name ${kb}KB ≥ ${max_kb}KB" >&2; bad=1
    fi
    if [ "$sgr" -le 0 ]; then
        echo "  不合格: $name 没有 ANSI 颜色（提示符应该是彩色的）" >&2; bad=1
    fi
    if [ "$prompt" != yes ]; then
        echo "  不合格: $name 看不到提示符行" >&2; bad=1
    fi
    if [ ! -f "$ansi" ]; then
        echo "  不合格: $name 缺整屏捕获 $ansi" >&2; bad=1
    fi
done
if [ "$bad" -eq 0 ]; then
    echo "全部通过（$(ls "$root"/img/*.png | wc -l | tr -d ' ') 张）" >&2
fi
exit "$bad"
