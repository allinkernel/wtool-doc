#!/usr/bin/env python3
"""把带 ANSI 颜色的终端输出渲染成 PNG（ImageMagick pango 后端，无第三方库）。

    script -qec '<命令>' /tmp/x.ansi
    term-shot.py /tmp/x.ansi img/x.png

要点（踩过的坑，别改回去）：
  · ImageMagick 的安全策略禁止 `pango:@file`，markup 只能**当参数**传（本脚本用 argv，不经 shell）；
  · pango 会把连续空格折成一个 → 全部换成 U+00A0；
  · 字体用 `font_desc`，写在每个 span 上（继承不可靠）。
"""
import os, re, subprocess, sys

FG = {30: '#3b3b3b', 31: '#e06c75', 32: '#98c379', 33: '#e5c07b', 34: '#61afef',
      35: '#c678dd', 36: '#56b6c2', 37: '#dcdfe4', 90: '#7f848e', 91: '#e06c75',
      92: '#98c379', 93: '#e5c07b', 94: '#61afef', 95: '#c678dd', 96: '#56b6c2', 97: '#ffffff'}
BG = {40: '#21252b', 41: '#e06c75', 42: '#98c379', 44: '#61afef', 45: '#c678dd', 46: '#56b6c2', 47: '#dcdfe4'}
DEF_FG, FACEBG, FONT = '#dcdfe4', '#282c34', 'DejaVu Sans Mono 14'

SGR = re.compile(r'\x1b\[([0-9;]*)m')
CSI = re.compile(r'\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*(\x07|\x1b\\)|\x1b[=>]')


def parse(text):
    segs, fg, bg, bold, i = [], DEF_FG, None, False, 0
    for m in SGR.finditer(text):
        segs.append((text[i:m.start()], fg, bg, bold))
        i = m.end()
        codes = [int(c) for c in m.group(1).split(';') if c != ''] or [0]
        for c in codes:
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
    segs.append((text[i:], fg, bg, bold))
    return segs


def esc(s):
    # ⚠️ `&amp;` 会被 ImageMagick 先展开成 `&`，再交给 pango 就报
    #    "Entity did not end with a semicolon" —— 用**数字实体** `&#38;` 才不被二次展开。
    return s.replace('&', '&#38;').replace('<', '&#60;').replace('>', '&#62;')


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
        sys.exit('用法: term-shot.py <带 ANSI 的终端输出文件> <输出.png>')
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, 'rb') as f:
        raw = f.read().decode('utf-8', 'replace')
    raw = raw.replace('\r\n', '\n').replace('\r', '\n')
    # script(1) 会在首尾各加一行（"Script started/done ..."），那不是命令输出，丢掉
    raw = '\n'.join(l for l in raw.split('\n')
                     if not l.lstrip().startswith(('Script started on', 'Script done on')))
    markup = to_pango(parse(CSI.sub('', raw)))
    if not markup.strip():
        sys.exit('输入是空的')
    os.makedirs(os.path.dirname(dst) or '.', exist_ok=True)
    cmd = ['convert', '-background', FACEBG, '-bordercolor', FACEBG, '-border', '16',
           'pango:' + markup, dst]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit('convert 失败: ' + (r.stderr or '')[:300])
    print(dst)


if __name__ == '__main__':
    main()
