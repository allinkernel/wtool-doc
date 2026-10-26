#!/bin/sh
# doc-coverage.sh —— 从一台已 bootstrap 的机器收集"用户能用到的名字"，逐个对 wtool.md + tutorial.md。
#
#   sh scripts/doc-coverage.sh [文档...]
#
# 不给文档就扫 wtool.md 和 tutorial.md；两份合起来覆盖全部名字。
# 默认在 VM 上收集，可用 DOC_COVER_HOST 换机器：
#   DOC_COVER_HOST=mindul@192.168.76.136 sh scripts/doc-coverage.sh
# 只在本机收集（工作区 + ~/.wtool/usr/bin）：
#   DOC_COVER_HOST=none sh scripts/doc-coverage.sh
#
# 收集：$WTOOL_HOME/usr/bin 下的可执行名、zsh/bash 的 custom 函数与别名、
#       `wtool _complete` 的子命令。custom = 完整 env 减去只加载 oh-my-zsh 的基线。
# 比对：名字必须出现在任一份文档的 H3 标题，或表格第一列。
# 退出码：0 = 全部覆盖；1 = 有未覆盖；2 = 收集失败。
set -eu

HOST=${DOC_COVER_HOST:-mindul@192.168.76.136}
here=$(cd -- "$(dirname -- "$0")/.." && pwd)

if [ $# -eq 0 ]; then
    set -- wtool.md tutorial.md
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/wtool-doc-cover.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT INT TERM
inv=$tmp/inventory.txt
docs=$tmp/docs.txt
: > "$inv"
: > "$docs"
for d in "$@"; do
    case $d in /*) ;; *) d=$here/$d ;; esac
    printf '%s\n' "$d" >> "$docs"
done

if [ "$HOST" = none ]; then
    echo "doc-coverage: DOC_COVER_HOST=none，只在本机收集" >&2
else
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" 'sh -s' > "$inv" <<'REMOTE' || {
set -u
WH=$HOME/.wtool
tmp=$(mktemp -d "${TMPDIR:-/tmp}/wtool-doc-cover-remote.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT INT TERM
Z=$WH/usr/bin/zsh
B=/usr/bin/bash
zt() { env -i HOME=$HOME PATH=$WH/usr/bin:/usr/bin:/bin TERM=xterm WTOOL_HOME=$WH \
        "$Z" -f -i -c "source $WH/.zshenv >/dev/null 2>&1; $1" 2>/dev/null; }
ztb() { env -i HOME=$HOME PATH=$WH/usr/bin:/usr/bin:/bin TERM=xterm WTOOL_HOME=$WH \
        WTOOL_PROJECT_DIR=$WH/wtool/shell/oh-my-zsh "$Z" -f -i -c \
        "source $WH/.zshenv >/dev/null 2>&1; $1" 2>/dev/null; }
bt() { env -i HOME=$HOME PATH=$WH/usr/bin:/usr/bin:/bin TERM=xterm WTOOL_HOME=$WH \
        "$B" --norc --noprofile -i -c "$1" 2>/dev/null; }

echo '# bins'
for f in "$WH/usr/bin"/*; do
    [ -e "$f" ] || continue
    b=${f##*/}
    case $b in .*) continue ;; esac
    printf '%s\n' "$b"
done | sort -u

echo '# zsh functions'
zt 'source '"$WH"'/env.zsh >/dev/null 2>&1; print -l ${(k)functions}' | sort -u > "$tmp/zf"
ztb 'source '"$WH"'/wtool/shell/oh-my-zsh/env.zsh >/dev/null 2>&1; print -l ${(k)functions}' | sort -u > "$tmp/zb"
comm -23 "$tmp/zf" "$tmp/zb" | grep -v '^_' | sort -u

echo '# zsh aliases'
zt 'source '"$WH"'/env.zsh >/dev/null 2>&1; alias -L' | sort -u > "$tmp/za"
ztb 'source '"$WH"'/wtool/shell/oh-my-zsh/env.zsh >/dev/null 2>&1; alias -L' | sort -u > "$tmp/zab"
comm -23 "$tmp/za" "$tmp/zab" | sed -n 's/^alias \(-g \)\?\([^=]*\)=.*/\2/p' | sort -u

echo '# bash functions'
bt 'source '"$WH"'/env.bash >/dev/null 2>&1; declare -F' | awk '{print $3}' | sort -u > "$tmp/bf"
bt 'declare -F' | awk '{print $3}' | sort -u > "$tmp/bb"
comm -23 "$tmp/bf" "$tmp/bb" | grep -v '^_' | sort -u

echo '# bash aliases'
bt 'source '"$WH"'/env.bash >/dev/null 2>&1; alias -p' | sort -u > "$tmp/ba"
bt 'alias -p' | sort -u > "$tmp/bab"
comm -23 "$tmp/ba" "$tmp/bab" | sed -n 's/^alias \([^=]*\)=.*/\1/p' | sort -u

echo '# wtool commands'
env -i HOME=$HOME PATH=$WH/wtool/wtool-base-tools/bin:$WH/usr/bin:/usr/bin:/bin TERM=xterm \
    WTOOL_HOME=$WH WTOOL_STATE=$WH/var WTOOL_PREFIX=$WH/usr \
    "$WH/wtool/wtool-base-tools/bin/wtool" _complete '' 2>/dev/null | sort -u
REMOTE
    echo "doc-coverage: 收集失败（$HOST）；用 DOC_COVER_HOST 指定一台已 bootstrap 的机器，或 DOC_COVER_HOST=none 只在本机收集" >&2
    exit 2
}
fi

# 本机（工作区）也收集一份：VM 上 /usr/bin 可能被清空，或没装 dsh 那一族。
# 合并进同一份 inventory，取并集。
local_inventory() {
    R=$(cd -- "$here/.." && pwd)
    T=$(mktemp -d "${TMPDIR:-/tmp}/wtool-doc-cover-local.XXXXXX")
    WH=$T/wh; mkdir -p "$WH/var" "$T/home"
    P=$(find "$R/tools/musl-bins" -type d -path '*/__output/usr/bin' 2>/dev/null | tr '\n' ':')
    P=$P$R/shell/zsh/__output/usr/bin:$R/wtool-base-tools/bin:/usr/bin:/bin

    echo '# bins'
    for f in "$R"/tools/musl-bins/*/__output/usr/bin/* \
             "$R"/shell/zsh/__output/usr/bin/zsh \
             "$R"/shell/zsh/__output/usr/bin/zsh-5.9.2 \
             "$R"/tools/android_repack/bin/wpack \
             "$R"/dsh-projects/dsh-remote/bin/*; do
        [ -e "$f" ] || continue
        [ -x "$f" ] || continue
        printf '%s\n' "${f##*/}"
    done | sort -u

    cat > "$T/z.zsh" <<ZS
export WTOOL_HOME=$WH WTOOL_STATE=$WH/var WTOOL_PREFIX=$WH/usr
export WTOOL_MANAGED_HOME=$T/home WTOOL_ROOT=$R
export PATH="$P"
for p in shell/shell-rc tools/git-repo-sh-tools terminal/tmux \
         tools/musl-bins/fzf tools/musl-bins/zoxide tools/musl-bins/navi \
         tools/musl-bins/starship; do
    export WTOOL_PROJECT_DIR="\$WTOOL_ROOT/\$p"
    [ -r "\$WTOOL_PROJECT_DIR/env.zsh" ] && . "\$WTOOL_PROJECT_DIR/env.zsh"
done
print -l \${(k)functions}
ZS
    echo '# zsh functions'
    env -i HOME="$T/home" TERM=xterm /usr/bin/zsh -f -i "$T/z.zsh" 2>/dev/null |
        sort -u | grep -v '^_' | grep -v -x -e add-zsh-hook || true

    cat > "$T/z2.zsh" <<ZS
export WTOOL_HOME=$WH WTOOL_STATE=$WH/var WTOOL_PREFIX=$WH/usr
export WTOOL_MANAGED_HOME=$T/home WTOOL_ROOT=$R
export PATH="$P"
for p in shell/shell-rc terminal/tmux; do
    export WTOOL_PROJECT_DIR="\$WTOOL_ROOT/\$p"
    [ -r "\$WTOOL_PROJECT_DIR/env.zsh" ] && . "\$WTOOL_PROJECT_DIR/env.zsh"
done
alias -L
ZS
    echo '# zsh aliases'
    env -i HOME="$T/home" TERM=xterm /usr/bin/zsh -f -i "$T/z2.zsh" 2>/dev/null |
        sed -n 's/^alias \(-g \)\?\([^=]*\)=.*/\2/p' | sort -u |
        grep -v -x -e run-help -e which-command || true

    cat > "$T/b.bash" <<BS
export WTOOL_HOME=$WH WTOOL_STATE=$WH/var WTOOL_PREFIX=$WH/usr
export WTOOL_MANAGED_HOME=$T/home WTOOL_ROOT=$R
export PATH="$P"
for p in shell/shell-rc tools/git-repo-sh-tools terminal/tmux \
         tools/musl-bins/fzf tools/musl-bins/zoxide tools/musl-bins/navi; do
    export WTOOL_PROJECT_DIR="\$WTOOL_ROOT/\$p"
    [ -r "\$WTOOL_PROJECT_DIR/env.bash" ] && . "\$WTOOL_PROJECT_DIR/env.bash"
done
declare -F
BS
    echo '# bash functions'
    env -i HOME="$T/home" TERM=xterm /usr/bin/bash --norc --noprofile -i "$T/b.bash" 2>/dev/null |
        awk '{print $3}' | sort -u | grep -v '^_' || true

    echo '# bash aliases'
    sed -i 's/declare -F/alias -p/' "$T/b.bash" 2>/dev/null || true
    env -i HOME="$T/home" TERM=xterm /usr/bin/bash --norc --noprofile -i "$T/b.bash" 2>/dev/null |
        sed -n 's/^alias \([^=]*\)=.*/\1/p' | sort -u || true

    echo '# wtool commands'
    env -i HOME="$T/home" PATH="$P" TERM=xterm WTOOL_HOME="$WH" \
        WTOOL_STATE="$WH/var" WTOOL_PREFIX="$WH/usr" \
        "$R/wtool-base-tools/bin/wtool" _complete '' 2>/dev/null | sort -u
    rm -rf -- "$T"
}

# 本机 .wtool/usr/bin 里的 dsh / wpack 一族（VM 上不一定装了它们）
if [ "${DOC_COVER_LOCAL_BINS:-1}" = 1 ]; then
    echo '# host bins' >> "$inv"
    for f in "$HOME"/.wtool/usr/bin/dsh-* "$HOME"/.wtool/usr/bin/harness-remote \
             "$HOME"/.wtool/usr/bin/wpack; do
        [ -e "$f" ] || continue
        printf '%s\n' "${f##*/}"
    done | sort -u >> "$inv"
fi

local_inventory >> "$inv"

# 文档里认可的名字：H3 标题 + 表格第一列（几份文档取并集）。
python3 - "$docs" "$inv" <<'PY'
import os, re, sys

doclist, inv = sys.argv[1], sys.argv[2]
with open(doclist, encoding="utf-8") as fh:
    docs = [l.strip() for l in fh if l.strip()]

have = set()
for doc in docs:
    with open(doc, encoding="utf-8") as fh:
        for line in fh:
            s = line.strip()
            if s.startswith("### "):
                t = s[4:].strip().strip("`")
                have.add(t)
                if t.startswith("wtool "):
                    have.add(t[6:])
            elif s.startswith("|"):
                cells = [c.strip().strip("`") for c in s.strip("|").split("|")]
                if cells:
                    have.add(cells[0])
                    # 也收 "| `名字` |" 这种首列
                    m = re.match(r"^`([^`]+)`", cells[0])
                    if m:
                        have.add(m.group(1))

section = ""
items = []
with open(inv, encoding="utf-8") as fh:
    for line in fh:
        s = line.rstrip("\n")
        if s.startswith("# "):
            section = s[2:]
            continue
        if s.strip():
            items.append((section, s.strip()))

missing = []
seen = set()
for sec, name in items:
    if not name or name.startswith("_"):
        continue
    if name in seen:
        continue
    seen.add(name)
    if name not in have:
        missing.append((sec, name))

print("扫描 %s" % " ".join(os.path.basename(d) for d in docs))
for sec, name in missing:
    print("未覆盖：%s（%s）" % (name, sec))
print("检查 %d 个名字：已覆盖 %d，未覆盖 %d" % (len(seen), len(seen) - len(missing), len(missing)))
sys.exit(1 if missing else 0)
PY
