#!/bin/sh
# 逐张检查 img/*.png 的截图颜色：
#   - 原转录里命令输出有 SGR → PNG 的 %k 必须 > 100；
#   - 命令输出没有 SGR     → 只打印一行"该命令本身不输出颜色"，不算失败。
#
#   sh scripts/check-shot-colors.sh
set -eu
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
scratch=${WTOOL_SHOT_DIR:-/tmp/wtool-shot}
bad=0
printf 'name\tsgr\tcolors\n'
for png in "$root"/img/*.png; do
    name=${png##*/}; name=${name%.png}
    ansi=$scratch/$name.ansi
    if [ ! -f "$ansi" ]; then
        printf '%s\t-\t-\t缺少转录\n' "$name"
        bad=1
        continue
    fi
    sgr=$(tail -n +2 "$ansi" | grep -aoE "$(printf '\033\\[[0-9;]*m')" | wc -l | tr -d ' ')
    colors=$(identify -format '%k' "$png" 2>/dev/null || echo 0)
    colors=${colors:-0}
    printf '%s\t%s\t%s\n' "$name" "$sgr" "$colors"
    if [ "$sgr" -gt 0 ] && [ "$colors" -le 100 ]; then
        echo "颜色判据失败: $name（SGR $sgr，PNG $colors 色）" >&2
        bad=1
    fi
done
exit $bad
