#!/usr/bin/env python3
"""Vygeneruje ios/GymBarWatch/WatchStrings.swift z wear/lib/strings.dart.

Texty aplikace pro Apple Watch jsou stejné jako u Wear OS (10 jazyků).
Po změně wear/lib/strings.dart spusť znovu:

    python3 tool/ios_watch_strings.py

test/apple_watch_test.dart hlídá, že je soubor aktuální (--check).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'wear/lib/strings.dart'
OUT = ROOT / 'ios/GymBarWatch/WatchStrings.swift'

LANGS = {'_Cs': 'cs', '_En': 'en', '_De': 'de', '_Es': 'es', '_Fr': 'fr',
         '_It': 'it', '_Nl': 'nl', '_Pl': 'pl', '_Pt': 'pt', '_Sk': 'sk'}


def dart_string(expr: str) -> str:
    """'a' 'b' → ab (sousední literály), bez escapů kromě \\'."""
    parts = re.findall(r"'((?:[^'\\]|\\.)*)'", expr)
    return ''.join(parts).replace("\\'", "'")


def swift_literal(text: str) -> str:
    text = text.replace('\\', '\\\\').replace('"', '\\"')
    text = re.sub(r'\$\{(\w+)\}', r'\\(\1)', text)
    text = re.sub(r'\$(\w+)', r'\\(\1)', text)
    return f'"{text}"'


def parse():
    src = SRC.read_text(encoding='utf-8')
    abstract = src[src.index('abstract class WearStrings'):]
    abstract = abstract[:abstract.index('\n}\n')]
    getters = re.findall(r'String get (\w+);', abstract)
    defaults = dict(re.findall(r"String get (\w+) => '([^']*)';", abstract))
    funcs = re.findall(r'String (\w+)\(([^)]*)\);', abstract)
    langs = {}
    for cls, code in LANGS.items():
        start = src.index(f'class {cls} extends WearStrings')
        body = src[start:src.index('\n}\n', start)]
        values = {}
        for name in getters:
            m = re.search(rf'String get {name} =>\s*((?:\'(?:[^\'\\]|\\.)*\'\s*)+);', body)
            if not m:
                sys.exit(f'{cls}: chybí {name}')
            values[name] = dart_string(m.group(1))
        for name, val in defaults.items():
            m = re.search(rf'String get {name} =>\s*((?:\'(?:[^\'\\]|\\.)*\'\s*)+);', body)
            values[name] = dart_string(m.group(1)) if m else val
        for name, params in funcs:
            m = re.search(rf'String {name}\([^)]*\) =>\s*((?:\'(?:[^\'\\]|\\.)*\'\s*)+);', body)
            if not m:
                sys.exit(f'{cls}: chybí {name}()')
            values[name] = dart_string(m.group(1))
        comma = re.search(r'bool get decimalComma => (true|false);', body)
        values['decimalComma'] = comma.group(1) if comma else 'true'
        langs[code] = values
    return getters + list(defaults), funcs, langs


def main():
    getters, funcs, langs = parse()
    out = ['// VYGENEROVÁNO z wear/lib/strings.dart nástrojem',
           '// tool/ios_watch_strings.py – neupravovat ručně.',
           '// Texty aplikace pro Apple Watch (stejné jako Wear OS, 10 jazyků).',
           'import Foundation', '',
           'struct WatchStrings {',
           '  let decimalComma: Bool']
    for name in getters:
        out.append(f'  let {name}: String')
    for name, params in funcs:
        types = ', '.join('Int' if p.strip().startswith('int') else 'String'
                          for p in params.split(','))
        out.append(f'  let {name}: ({types}) -> String')
    out += ['',
            '  /// Texty podle jazyka hodinek (neznámý jazyk anglicky).',
            '  static func current() -> WatchStrings {',
            '    let code = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"',
            '    return all[code] ?? all["en"]!',
            '  }', '',
            '  static let all: [String: WatchStrings] = [']
    for code, values in langs.items():
        out.append(f'    "{code}": WatchStrings(')
        out.append(f'      decimalComma: {values["decimalComma"]},')
        for name in getters:
            out.append(f'      {name}: {swift_literal(values[name])},')
        for i, (name, params) in enumerate(funcs):
            names = [p.strip().split()[-1] for p in params.split(',')]
            sep = ',' if i < len(funcs) - 1 else ''
            out.append(f'      {name}: {{ {", ".join(names)} in {swift_literal(values[name])} }}{sep}')
        out.append('    ),')
    out += ['  ]', '}', '']
    text = '\n'.join(out)
    if '--check' in sys.argv:
        if OUT.read_text(encoding='utf-8') != text:
            sys.exit(f'✗ {OUT.relative_to(ROOT)} není aktuální – spusť '
                     'python3 tool/ios_watch_strings.py')
        print(f'✓ {OUT.relative_to(ROOT)} je aktuální')
        return
    OUT.write_text(text, encoding='utf-8')
    print(f'✓ {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
