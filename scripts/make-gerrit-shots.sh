#!/bin/sh
# gerrit 场景截图：**真 gerrit 服务器** + 真 AOSP 仓库（platform/packages/apps/Settings）。
#
#   sh scripts/make-gerrit-shots.sh [--only 名字]
#
# 参数来自另一路搭好的环境（不在这里编造）：
#   /tmp/gerrit-demo.ready   GERRIT_HOST / GERRIT_SSH_PORT / GERRIT_HTTP / GERRIT_ADMIN
#                            / GERRIT_PROJECT / GERRIT_CHANGES / GERRIT_WORKTREE
#   /home/mindul/data/gerrit-demo/env-demo.zsh   场景环境（gerrit 地址 + 真 git-repo-sh-tools）
#   /home/mindul/data/gerrit-demo/scenes/*.sh    场景脚本：**直接调用**，不改内容
#
# 场景脚本自己会 `print -r -- '$ 命令'` 再执行，所以图里是「提示符 + 脚本 + 它跑的那几条命令 + 真输出」。
# 不在 scenes/ 里的那些（gq / gchk / ggcp 失败 / ggrvt 失败 / gba / gbb / ggco / gpush / gpun /
# cdd -N 失败）照同一套环境**真敲命令**。
#
# 真服务器偶尔会 `kex_exchange_identification: Connection reset by peer`（容器里的 sshd 掐连接），
# 所以每个场景跑完都核对一眼输出，不对就重跑（最多 4 次）。
set -eu
here=$(cd -- "$(dirname -- "$0")" && pwd)
ready=/tmp/gerrit-demo.ready
[ -f "$ready" ] || { echo "gerrit 还没就绪：$ready 不在" >&2; exit 1; }
# shellcheck disable=SC1090
. "$ready"
D=/home/mindul/data/gerrit-demo
PROJ=$GERRIT_WORKTREE/packages/apps/Settings
BASE=$(cut -d= -f2 "$D/base-sha")
GHOME=/tmp/wtool-gerrit-home
SCRATCH=${WTOOL_SHOT_DIR:-/tmp/wtool-shot}
report=$SCRATCH/report-gerrit.tsv
only=''
[ "${1:-}" = --only ] && { only=$2; shift 2; }
: > "$report"

# 场景用的家目录：wtool 的 env（ys 提示符 / 别名）+ gerrit demo 的 env（服务器地址 / 仓库工具）。
# .wtool 直接软链用户的（只读用），不复制。
fresh_home() {
    rm -rf "$GHOME"; mkdir -p "$GHOME"
    ln -s "$HOME/.wtool" "$GHOME/.wtool"
    {
        echo 'export WTOOL_HOME=~/.wtool'
        echo 'source ${WTOOL_HOME}/env.zsh'
        # ⚠️ 顺序：先 wtool 的 env（提示符/主题），再 demo 的 env —— 后者会 unset WTOOL_*，
        #    放前面会让提示符和别名都没了。
        echo "source $D/env-demo.zsh"
        # gbb / ggco / gpun 是直接调 git 的，得让 git 用 demo 那把 key（ggcp/gpush 自己会设）
        # env-demo.zsh 会 unset 所有 WTOOL_*；direnv 的 precmd 钩子还等着 $WTOOL_HOME
        # （不补回来，每个提示符前都会刷一行 `/usr/bin/direnv: no such file`）。
        echo 'export WTOOL_HOME=~/.wtool'
        echo "export GIT_SSH_COMMAND='ssh -i $D/keys/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR'"
        echo 'export GIT_TERMINAL_PROMPT=0'
    } > "$GHOME/.zshrc"
}
fresh_home

# 每个场景开始前把工作树放回基线（干净、在 main 上），场景脚本自己也会 reset
reset_tree() {
    git -C "$PROJ" reset -q --hard "$BASE"
    git -C "$PROJ" checkout -q -B main "$BASE"
    git -C "$PROJ" clean -qfd
}

run_scene() {   # name okpat -- shot 参数...
    name=$1; okpat=$2; shift 2
    if [ -n "$only" ] && [ "$only" != "$name" ]; then return 0; fi
    reset_tree
    i=0
    while [ "$i" -lt 4 ]; do
        i=$((i + 1))
        sh "$here/shot.sh" "$name" --dir "$PROJ" --home "$GHOME" -- "$@" | tee -a "$report"
        if [ -z "$okpat" ] || grep -qE "$okpat" "$SCRATCH/$name.log" 2>/dev/null; then
            return 0
        fi
        echo "  $name 输出不对（第 $i 次），重跑" >&2
        sleep 5
    done
    echo "  !! $name 重跑 4 次都不对，如实留图" >&2
    return 0
}

echo "gerrit: $GERRIT_HTTP  $GERRIT_ADMIN@$GERRIT_HOST:$GERRIT_SSH_PORT  $GERRIT_PROJECT"
echo "changes: $GERRIT_CHANGES（场景见 $D/scenes/）"

# ① 直接调用另一路提供的场景脚本
run_scene ggcp-ok            '成功 1 / 失败 0'  "zsh $D/scenes/ggcp-ok.sh"
run_scene ggcp-multi         '成功 2 / 失败 0'  "zsh $D/scenes/ggcp-multi.sh"
run_scene ggcp-same-change   'Change-Id'        "zsh $D/scenes/ggcp-fail-same-change.sh"
run_scene ggrvt-ok           'ggrvt|回退'        "zsh $D/scenes/ggrvt-ok.sh"
run_scene gb                 'remote: gerrit'   "zsh $D/scenes/gb.sh"
run_scene cdd-dash           'packages/apps/Settings' "zsh $D/scenes/cdd.sh"

# ② 同一套环境里真敲命令（服务器、仓库、change 编号都是真的）
run_scene ggcp-fail          '查不到 change 99'  'ggcp 99'
run_scene ggrvt-fail         '本地历史里没有'     'ggrvt 1'
run_scene gq                 'NEW.*Settings'     'gq 1'
run_scene gchk               'change 1'          'gchk 1'
run_scene cdd-dash-fail      '查不到 change 99'  'cdd -99'
run_scene gba                'gerrit/main'       'gba'
run_scene gbb                'refs/for|HEAD:main' 'gbb'
run_scene ggco               'ggco'              'ggco main'
run_scene gpun               'gpun'              'gpun -30'
# gpush 要有东西可推：先做一个带 Change-Id 的提交，再真推到 refs/for/main
reset_tree
git -C "$PROJ" -c user.name=demo -c user.email=demo@example.com \
    commit -q --allow-empty -m "demo: gpush scene

Change-Id: $(printf 'I%040d' 7)"
run_scene gpush              'refs/for/main|remote:' 'gpush'

echo "报告: $report"
