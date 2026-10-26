#!/bin/sh
# 按 scripts/scenes.tsv 重新生成全部文档截图。
#
#   sh scripts/make-shots.sh                 # 全部
#   sh scripts/make-shots.sh --only cs       # 只重做一张（调试用）
#   sh scripts/make-shots.sh --gerrit        # 只做 gerrit 那组（要 /tmp/gerrit-demo.ready）
#
# 每张图 = 真 tmux 终端里的真交互 zsh（~/.zshrc → $WTOOL_HOME/env.zsh → oh-my-zsh ys 主题），
# 命令用 `tmux send-keys` 当键入送进去，`capture-pane` 抓整屏。见 scripts/shot.sh 头注释。
#
# 沙箱家目录（不碰用户的真 $HOME）：
#   demo  /tmp/wtool-demo-home   真 ~/.wtool 的副本，账本一致（check 干净）——
#                                install/uninstall/check/kill 这类会写东西的场景用它
#   fresh /tmp/wtool-fresh-home  只有 env 副本、没有"装过"的记录 —— 演示"装之前"的状态
set -eu
here=$(cd -- "$(dirname -- "$0")" && pwd)
WS=${WTOOL_WS:-/home/mindul/self/wtool}
table=$here/scenes.tsv
only=''; want_gerrit=0
while [ $# -gt 0 ]; do
    case $1 in
        --only)   only=$2; shift 2 ;;
        --gerrit) want_gerrit=1; shift ;;
        *) echo "用法: make-shots.sh [--only 名字] [--gerrit]" >&2; exit 2 ;;
    esac
done
sh "$here/make-sandbox-home.sh" >/dev/null
report=${WTOOL_SHOT_DIR:-/tmp/wtool-shot}/report.tsv
: > "$report"

# pss / pdd 读的是 pwd 函数记下的那个文件（见 shell-rc 的 env.zsh）；先按同样的规则放一份，
# 这样单独重做这两张也能出图。
(cd /tmp && printf '/tmp\n' > "/tmp/wsw-temp-pwd-id-$(id -u)")

sandbox() {
    case $1 in
        real) printf '%s' "$HOME" ;;
        demo) printf '%s' /tmp/wtool-demo-home ;;
        fresh) printf '%s' /tmp/wtool-fresh-home ;;
        *) echo "scenes.tsv: 不认识的 home: $1" >&2; exit 2 ;;
    esac
}

want=0
# 第 1 遍：tsv 里的场景（--only 过滤）
while IFS="$(printf '\t')" read -r name shell dir home cmd; do
    case $name in ''|'#'*) continue ;; esac
    if [ -n "$only" ] && [ "$only" != "$name" ]; then continue; fi
    want=1
    sh "$here/shot.sh" "$name" --shell "$shell" --dir "$dir" --home "$(sandbox "$home")" -- "$cmd" \
        | tee -a "$report"
    # wtool init 会在工作区里造 demo/new：写完就删，别让它出现在别张图的总览表里
    if [ "$name" = wtool-init ]; then rm -rf "$WS/demo"; fi
done < "$table"

# 第 2 遍：gerrit 那组（真服务器；参数从 /tmp/gerrit-demo.ready 读）
if [ "${only:-}" != '' ]; then
    if grep -qx "$only" "$here/scenes-gerrit.tsv" 2>/dev/null; then want_gerrit=1; fi
fi
if [ "$want_gerrit" -eq 1 ]; then
    [ -f /tmp/gerrit-demo.ready ] || { echo "gerrit 还没就绪（/tmp/gerrit-demo.ready 不在）" >&2; exit 1; }
    if [ -n "$only" ]; then
        sh "$here/make-gerrit-shots.sh" --only "$only" | tee -a "$report"
    else
        sh "$here/make-gerrit-shots.sh" | tee -a "$report"
    fi
elif [ "$want" -eq 0 ] && [ -z "$only" ]; then
    echo "scenes.tsv 里没有场景" >&2
fi

echo "报告: $report"
