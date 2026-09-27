#!/usr/bin/env python3
"""Build native Rive paths from Google Fonts Noto Sans TC or JP.

Use --locale ja for Japanese. Run --download when adding characters; otherwise
the checked-in WOFF2 is sufficient. Requires fonttools[woff] (including brotli).
"""
import argparse
import ast
import hashlib
import json
from io import BytesIO
import re
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from fontTools import subset
from fontTools.pens.basePen import BasePen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets' / 'fonts'


def fetch(url, user_agent='Mozilla/5.0 AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36'):
    request = Request(url, headers={'User-Agent': user_agent})
    with urlopen(request, timeout=45) as response:
        return response.read()


class RivePen(BasePen):
    def __init__(self, glyph_set, upem):
        super().__init__(glyph_set)
        self.upem = upem
        self.commands = []

    def point(self, point):
        x, y = point
        return f'{x / self.upem * 6:.4f} {(0.88 - y / self.upem) * 6:.4f}'

    def _moveTo(self, p):
        self.commands.append('M ' + self.point(p))

    def _lineTo(self, p):
        self.commands.append('L ' + self.point(p))

    def _curveToOne(self, a, b, c):
        self.commands.append('C ' + ' '.join(map(self.point, (a, b, c))))

    def _qCurveToOne(self, a, b):
        # Use cubics throughout: the local Rive script renderer drops portions
        # of quadratic font contours. This conversion preserves the exact curve.
        start = self._getCurrentPoint()
        c1 = tuple(start[i] + (a[i] - start[i]) * 2 / 3 for i in (0, 1))
        c2 = tuple(b[i] + (a[i] - b[i]) * 2 / 3 for i in (0, 1))
        self._curveToOne(c1, c2, b)

    def _closePath(self):
        self.commands.append('Z')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--download', action='store_true')
    parser.add_argument('--locale', choices=['zh-TW','ja'], default='zh-TW')
    args = parser.parse_args()
    japanese = args.locale == 'ja'
    region = 'jp' if japanese else 'tc'
    family = 'Noto Sans JP' if japanese else 'Noto Sans TC'
    license_name = 'OFL-NotoSans' + region.upper() + '.txt'
    font_path = ASSETS / f'noto-sans-{region}-700.woff2'
    # Read only this locale's dialogue column so regional fonts stay separate.
    literal = r"""(?:'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")"""
    catalog = (ROOT / ('localization_ja.luau' if japanese else 'localization.luau')).read_text()
    source = ''.join(ast.literal_eval(m[2]) for m in re.finditer(r'\[('+literal+r')\]\s*=\s*('+literal+r')',catalog))
    source += '日本語' if japanese else '繁中（台灣）'
    for name in ['remarks_catalog.luau','boss_remarks.luau']:
        for match in re.finditer(r'\{\s*('+literal+r')\s*,\s*('+literal+r')\s*,\s*('+literal+r')\s*\}', (ROOT/name).read_text()):
            source += ast.literal_eval(match[3 if japanese else 2])
    if japanese:
        host = (ROOT/'web/host-strings.mjs').read_text()
        source += '日本語' + host[host.index('  ja: {'):host.index("  'zh-TW': {")]

    chars = ''.join(sorted({c for c in source if ord(c) > 127}))
    if args.download:
        ASSETS.mkdir(parents=True, exist_ok=True)
        css_url = 'https://fonts.googleapis.com/css2?' + urlencode({
            'family': family + ':wght@700', 'display': 'swap', 'text': chars})
        css = fetch(css_url).decode()
        urls = re.findall(r'url\((https://fonts.gstatic.com/[^)]+)\)', css)
        if len(urls) != 1:
            # Large text requests can return many unicode-range faces. Request
            # the complete legacy face, then subset locally instead of saving
            # only the first (incomplete) WOFF2 fragment.
            css = fetch(css_url, user_agent='Python-urllib/3').decode()
            urls = re.findall(r'url\((https://fonts.gstatic.com/[^)]+)\)', css)
        if len(urls) != 1:
            raise ValueError('Expected a single complete font face')
        url = urls[0]
        downloaded = fetch(url)
        downloaded_font = TTFont(BytesIO(downloaded))
        missing = [c for c in chars if ord(c) not in downloaded_font.getBestCmap()]
        if missing:
            raise ValueError(f'Downloaded font lacks requested glyphs: {missing}')
        if downloaded[:4] == b'wOF2':
            data = downloaded
        else:
            subsetter = subset.Subsetter()
            subsetter.populate(text=chars)
            subsetter.subset(downloaded_font)
            downloaded_font.flavor = 'woff2'
            buffer = BytesIO()
            downloaded_font.save(buffer)
            data = buffer.getvalue()
        font_path.write_bytes(data)
        (ASSETS / license_name).write_bytes(fetch(f'https://raw.githubusercontent.com/google/fonts/main/ofl/notosans{region}/OFL.txt'))
        (ASSETS / f'noto-sans-{region}-source.json').write_text(json.dumps({
            'family': family, 'weight': 700, 'css_url': css_url, 'font_url': url,
            'sha256': hashlib.sha256(data).hexdigest(), 'characters': chars,
        }, ensure_ascii=False, indent=2) + '\n')
    font = TTFont(font_path)
    cmap = font.getBestCmap()
    missing = [c for c in chars if ord(c) not in cmap]
    if missing:
        raise ValueError(f'Missing glyphs {missing}; rerun with --download')
    glyphs = font.getGlyphSet()
    lines = [f'-- Generated by tools/build_tc_font.py --locale {args.locale} from {family} Bold.',
             f'-- SIL Open Font License: assets/fonts/{license_name}. Do not edit by hand.',
             'return {']
    for char in chars:
        pen = RivePen(glyphs, font['head'].unitsPerEm)
        glyphs[cmap[ord(char)]].draw(pen)
        lines.append(f"    [{ord(char)}] = '{' '.join(pen.commands)}', -- {char}")
    lines.append('} :: { [number]: string }\n')
    (ROOT / f'{region}_glyphs.luau').write_text('\n'.join(lines))
    print(f'Generated {len(chars)} {family} glyphs from {font_path.stat().st_size:,} bytes of WOFF2')


if __name__ == '__main__':
    main()
