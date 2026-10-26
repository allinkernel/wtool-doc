#!/bin/sh
# 造两个"沙箱家目录"，给**会写东西 / 需要干净账本**的截图场景用 —— 全程不碰用户的真 $HOME。
#
#   /tmp/wtool-demo-home    真 ~/.wtool 的副本，账本一致（`wtool check` 干净）
#                           → check / install / uninstall / kill 这类场景
#   /tmp/wtool-fresh-home   只有 env 副本、没有"装过"的记录
#                           → 演示"还没装"的状态（status 全部未安装 / check 报没装过）
#
# 两个沙箱都只放两行 rc（就是文档让用户写的那两行），所以提示符照样来自
# oh-my-zsh 的 ys 主题（env.zsh 里的 omz 块指向工作区里的真项目）。
#
#   sh scripts/make-sandbox-home.sh
set -eu
real=$HOME
demo=/tmp/wtool-demo-home
fresh=/tmp/wtool-fresh-home
[ -d "$real/.wtool" ] || { echo "先装 wtool：$real/.wtool 不在" >&2; exit 1; }

rm -rf "$demo" "$fresh"
mkdir -p "$demo" "$fresh"
for h in "$demo" "$fresh"; do
    cp -a "$real/.wtool" "$h/.wtool"
    printf 'export WTOOL_HOME=~/.wtool\nsource ${WTOOL_HOME}/env.zsh\n' > "$h/.zshrc"
    printf 'export WTOOL_HOME=~/.wtool\nsource ${WTOOL_HOME}/env.bash\n' > "$h/.bashrc"
    # 每个项目的 env 副本保留（env.zsh 里 `[ -r 项目/env.zsh ] || source var 里的副本` 要用）
done

# demo：把**旧布局**留下的残账摘掉 —— `~/usr` 那条链（ADR-0046 起不再创建）和
# 改名后留下的 atuin 旧账。这不是"改账本糊弄 check"，而是让副本等价于一台
# 从头按当前版本装出来的机器（FRESH 装机不会产生这两类记录）。
awk -F'\t' -v bad="$real/usr" '!($1=="link" && $3==bad)' \
    "$demo/.wtool/var/wtool-base-tools/journal.tsv" > "$demo/.wtool/var/wtool-base-tools/journal.tsv.new"
mv "$demo/.wtool/var/wtool-base-tools/journal.tsv.new" "$demo/.wtool/var/wtool-base-tools/journal.tsv"
awk -F'\t' -v bad="$real/usr" '!($1=="link" && $3==bad)' \
    "$demo/.wtool/var/shell/shell-rc/journal.tsv" > "$demo/.wtool/var/shell/shell-rc/journal.tsv.new"
mv "$demo/.wtool/var/shell/shell-rc/journal.tsv.new" "$demo/.wtool/var/shell/shell-rc/journal.tsv"
rm -rf "$demo/.wtool/var/tools/musl-bins/atuin"
# ⚠️ terminal/tmux 的账**整条删掉**：这张账里的路径是**真家目录**的绝对路径，
# 留着它再在这个沙箱里跑 `wtool uninstall terminal/tmux`，就会按账去删**真**~/.wtool 里的链
# （2026-10-27 实测踩到：把真家目录的 L1 链删了，事后 wtool repair 才补回来）。
# 删掉之后沙箱里它显示"没装过"，install 场景真装一遍、uninstall 场景真撤一遍，都只动沙箱。
rm -rf "$demo/.wtool/var/terminal/tmux"

# fresh：清掉"装过"的记录（保留每个项目的 env 副本，否则 env.zsh 回退 source 会报错）
find "$fresh/.wtool/var" -type f \( -name 'meta.tsv' -o -name 'journal.tsv' \
    -o -name 'actions.tsv' -o -name 'plan*.tsv' -o -name 'publish.tsv' \
    -o -name 'registry.tsv' -o -name 'generated.tsv' \) -delete


# 第三个沙箱：musl 工具那 43 个**装好**的家目录 —— 教程里那些 `bat` / `fdfind` / `rg` 场景
# 要有可执行的工具（用户真机上装没装是另一回事，文档要能演示）。装一次就复用。
tools=/tmp/wtool-tools-home
if [ ! -e "$tools/.wtool/usr/bin/bat" ]; then
    rm -rf "$tools"; mkdir -p "$tools"
    cp -a "$real/.wtool" "$tools/.wtool"
    printf 'export WTOOL_HOME=~/.wtool\nsource ${WTOOL_HOME}/env.zsh\n' > "$tools/.zshrc"
    # ⚠️ 项目目录名 ≠ 命令名：btm←bottom、difft←difftastic、trip←trippy、
    #    mlr←miller、rg←ripgrep。按 __output/usr/bin 里的真二进制名反推。
    for p in $(ls -d /home/mindul/self/wtool/tools/musl-bins/*/ | sed 's#/home/mindul/self/wtool/##; s#/$##'); do
        ls "$p/__output/usr/bin/"* >/dev/null 2>&1 || continue
        ( cd /home/mindul/self/wtool && \
          HOME=$tools WTOOL_HOME=$tools/.wtool PATH=$tools/.wtool/wtool/wtool-base-tools/bin:$PATH \
          wtool install "$p" --force >/dev/null 2>&1 ) || echo "  装不上: $p" >&2
    done
fi
echo "tools : $tools  （$(ls "$tools"/.wtool/usr/bin | wc -l) 个入口）"

# 账本里的 `~/.wtool/...` 绝对路径全改到沙箱自己名下（项目根 `~/self/wtool/...` 保持真的）。
# 这样沙箱里 install/uninstall 只会动沙箱里的链。
for h in "$demo" "$fresh" "$tools"; do
    [ -d "$h/.wtool/var" ] || continue
    grep -rl "$real/.wtool" "$h/.wtool/var" 2>/dev/null | while IFS= read -r f; do
        sed -i "s#$real/\.wtool#$h/.wtool#g" "$f"
    done
done

if grep -rlq "$real/.wtool" "$demo/.wtool/var" 2>/dev/null; then
    echo "沙箱自检失败：$demo 的账本里还有 $real/.wtool 的绝对路径（会误删真家目录里的东西）" >&2
    exit 1
fi

echo "demo  : $demo  （$(HOME=$demo WTOOL_HOME=$demo/.wtool "$real/.wtool/wtool/wtool-base-tools/bin/wtool" check 2>&1 | head -1)）"
echo "fresh : $fresh （$(HOME=$fresh WTOOL_HOME=$fresh/.wtool "$real/.wtool/wtool/wtool-base-tools/bin/wtool" status 2>&1 | grep '个项目：' | head -1)）"
