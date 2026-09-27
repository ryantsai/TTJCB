#!/usr/bin/env python3
"""Reject hard-coded English in native draw calls and missing literal UI keys.
Dynamic campaign, equipment, tutorial and dialogue data are covered by Rive tests.
Keyboard/controller legends and the English language autonym are intentional.
"""
import ast
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
LITERAL = r'''(?:'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")'''

def check():
    catalog = (ROOT / 'localization.luau').read_text()
    keys = {ast.literal_eval(m[1]) for m in re.finditer(r'\[(' + LITERAL + r')\]\s*=', catalog)}
    legends = {'ENGLISH', 'H / Y', 'START / ENTER / ESC'}
    problems = []
    for path in ROOT.glob('*.luau'):
        if path.name.endswith('_test.luau') or path.name in {'localization.luau', 'tc_glyphs.luau'}:
            continue
        source = path.read_text()
        for m in re.finditer(r'G\.text\(\s*(' + LITERAL + r')', source):
            value = ast.literal_eval(m[1])
            if re.search('[A-Za-z]', value) and value not in legends:
                problems.append(f'{path.name}:{source[:m.start()].count(chr(10))+1}: raw text {value!r}')
        for m in re.finditer(r'(?:uiText|(?<!\w)text|L\.text|L\.format)\(\s*(?:g|locale|g\.locale)(?:\s+or\s+\x27en\x27)?\s*,\s*(' + LITERAL + r')', source):
            value = ast.literal_eval(m[1])
            if re.search('[A-Za-z]', value) and value not in keys and value not in legends:
                problems.append(f'{path.name}:{source[:m.start()].count(chr(10))+1}: missing translation {value!r}')
    if problems:
        raise SystemExit('\n'.join(problems))
    print('Native UI literal audit passed; no hard-coded English draw strings.')

if __name__ == '__main__':
    check()
