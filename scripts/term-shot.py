#!/usr/bin/env python3
"""把**整屏**终端捕获（tmux capture-pane -e 的输出）渲染成 PNG。

    tmux capture-pane -p -e -t shot > /tmp/x.ansi
    term-shot.py /tmp/x.ansi img/x.png

和上一版（直接渲染 script(1) 的流水）的区别：
  · 输入是**最终屏幕**（提示符 + 命令 + 输出都在上面），不是逐字节流水 ——
    所以重画、回车擦行、异步提示符刷新这些都不会在图上留下残影；
  · 字体换成正版 JetBrains Mono（`JetBrainsLxgwNerdMono`，带中文和 Nerd 图标），
    字号 ≥18，图宽不足 1100px 时补背景到 1100px。

要点（踩过的坑，别改回去）：
  · ImageMagick 的安全策略禁止 `pango:@file`，markup 只能**当参数**传（本脚本用 argv，不经 shell）；
  · pango 会把连续空格折成一个 → 全部换成 U+00A0；
  · `&amp;` 会被 ImageMagick 先展开成 `&`，再交给 pango 就报错 → 用数字实体 `&#38;`；
  · 字体用 `font_desc`，写在每个 span 上（继承不可靠）；
  · SGR 必须**先解析成颜色再剥**（上一版先 `CSI.sub` 把 `\\x1b[…m` 一起删了，图永远是灰的）。
"""
import os, re, subprocess, sys

# 16 色（One Dark 调色板；和终端里的 ys 主题提示符同一个观感）
FG = {30: '#3b3b3b', 31: '#e06c75', 32: '#98c379', 33: '#e5c07b', 34: '#61afef',
      35: '#c678dd', 36: '#56b6c2', 37: '#dcdfe4',
      90: '#7f848e', 91: '#e06c75', 92: '#98c379', 93: '#e5c07b', 94: '#61afef',
      95: '#c678dd', 96: '#56b6c2', 97: '#ffffff'}
BG = {40: '#21252b', 41: '#e06c75', 42: '#98c379', 43: '#e5c07b', 44: '#61afef',
      45: '#c678dd', 46: '#56b6c2', 47: '#dcdfe4'}

DEF_FG, FACEBG = '#dcdfe4', '#282c34'
# 字体：JetBrains Mono + LXGW 中文字形 + Nerd 图标（一个文件全覆盖，不依赖 fontconfig fallback）
FONT = os.environ.get('SHOT_FONT', 'JetBrainsLxgwNerdMono 22')
MIN_WIDTH = int(os.environ.get('SHOT_MIN_WIDTH', '1100'))

SGR = re.compile(r'\x1b\[([0-9;:]*)m')
# 非 SGR 的 CSI / OSC 之类的控制序列（`m` 结尾的是颜色，必须留给 parse）
CSI_NON_SGR = re.compile(r'\x1b\[[0-9;?]*[A-Za-ln-z]|\x1b\][^\x07]*(\x07|\x1b\\)|\x1b[=>]')


def xterm256(n):
    """xterm 256 色 → #rrggbb（tmux 会吐 38;5;N，别把颜色丢了）。"""
    if n < 16:
        base = ['#000000', '#cd0000', '#00cd00', '#cdcd00', '#0000ee', '#cd00cd',
                '#00cdcd', '#e5e5e5', '#7f7f7f', '#ff0000', '#00ff00', '#ffff00',
                '#5c5cff', '#ff00ff', '#00ffff', '#ffffff']
        return base[n]
    if n < 232:
        n -= 16
        r, g, b = n // 36, (n % 36) // 6, n % 6
        conv = lambda v: 0 if v == 0 else 55 + v * 40
        return '#%02x%02x%02x' % (conv(r), conv(g), conv(b))
    v = 8 + (n - 232) * 10
    return '#%02x%02x%02x' % (v, v, v)


def parse(text):
    segs, fg, bg, bold, i = [], DEF_FG, None, False, 0
    for m in SGR.finditer(text):
        segs.append((text[i:m.start()], fg, bg, bold))
        i = m.end()
        codes = [int(c) for c in re.split(r'[;:]', m.group(1)) if c != ''] or [0]
        k = 0
        while k < len(codes):
            c = codes[k]
            if c == 0:
                fg, bg, bold = DEF_FG, None, False
            elif c == 1:
                bold = True
            elif c == 22:
                bold = False
            elif c == 39:
                fg = DEF_FG
            elif c == 49:
                bg = None
            elif c in FG:
                fg = FG[c]
            elif c in BG:
                bg = BG[c]
            elif c == 38 and k + 2 < len(codes) and codes[k + 1] == 5:
                fg = xterm256(codes[k + 2]); k += 2
            elif c == 48 and k + 2 < len(codes) and codes[k + 1] == 5:
                bg = xterm256(codes[k + 2]); k += 2
            elif c == 38 and k + 4 < len(codes) and codes[k + 1] == 2:
                fg = '#%02x%02x%02x' % tuple(codes[k + 2:k + 5]); k += 4
            elif c == 48 and k + 4 < len(codes) and codes[k + 1] == 2:
                bg = '#%02x%02x%02x' % tuple(codes[k + 2:k + 5]); k += 4
            k += 1
    segs.append((text[i:], fg, bg, bold))
    return segs


def esc(s):
    # `%` 也必须转成数字实体：ImageMagick 会把 pango 文本当**文件名**再解释一遍 `%` 转义
    # （`[C:2%]%` 这种百分比输出会把 markup 截断，报 "Element markup was closed ..."）。
    return (s.replace('&', '&#38;').replace('<', '&#60;').replace('>', '&#62;')
             .replace('%', '&#37;'))


def to_pango(segs):
    lines, cur = [], []
    for chunk, fg, bg, bold in segs:
        parts = chunk.split('\n')
        for j, part in enumerate(parts):
            if j:
                lines.append(cur)
                cur = []
            if part:
                attrs = 'font_desc="%s" foreground="%s"' % (FONT, fg)
                if bg:
                    attrs += ' background="%s"' % bg
                if bold:
                    attrs += ' weight="bold"'
                cur.append('<span %s>%s</span>' % (attrs, esc(part).replace(' ', '\u00a0')))
    lines.append(cur)
    out = [''.join(l).rstrip() for l in lines]
    while out and not out[-1].strip():
        out.pop()
    while out and not out[0].strip():
        out.pop(0)
    return '\n'.join(out)


def main():
    if len(sys.argv) != 3:
        sys.exit('用法: term-shot.py <整屏捕获文件> <输出.png>')
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, 'rb') as f:
        raw = f.read().decode('utf-8', 'replace')
    raw = raw.replace('\r\n', '\n').replace('\r', '\n')
    raw = CSI_NON_SGR.sub('', raw)
    markup = to_pango(parse(raw))
    if not markup.strip():
        sys.exit('输入是空的')
    os.makedirs(os.path.dirname(dst) or '.', exist_ok=True)
    tmp = dst + '.tmp.png'
    cmd = ['convert', '-background', FACEBG, '-bordercolor', FACEBG, '-border', '18',
           '-strip', '-depth', '8', 'pango:' + markup, tmp]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit('convert 失败: ' + (r.stderr or '')[:300])
    # 宽度不够就补背景（终端窗口本来就是矩形；短输出不许出小图）
    w = int(subprocess.run(['identify', '-format', '%w', tmp], capture_output=True,
                           text=True).stdout.strip() or 0)
    h = int(subprocess.run(['identify', '-format', '%h', tmp], capture_output=True,
                           text=True).stdout.strip() or 0)
    if w < MIN_WIDTH:
        r = subprocess.run(['convert', tmp, '-background', FACEBG,
                            '-gravity', 'West', '-extent', '%dx%d' % (MIN_WIDTH, h), dst],
                           capture_output=True, text=True)
        os.unlink(tmp)
        if r.returncode != 0:
            sys.exit('convert(extent) 失败: ' + (r.stderr or '')[:300])
    else:
        os.replace(tmp, dst)
    # 大图（长表格 / 宽的进程列表）> 280KB 就降到 64 色 PNG8：文字还是那个字，
    # 但文档仓库不该塞几百 KB 的单张图。
    if os.path.getsize(dst) > 280 * 1024:
        q = dst + '.q.png'
        r = subprocess.run(['convert', dst, '-colors', '64', 'PNG8:' + q],
                           capture_output=True, text=True)
        if r.returncode == 0 and os.path.getsize(q) < os.path.getsize(dst):
            os.replace(q, dst)
        else:
            if os.path.exists(q):
                os.unlink(q)
    print(dst)


if __name__ == '__main__':
    main()
