import re
import glob

dart_files = glob.glob('lib/**/*.dart', recursive=True)

todos = []
fixmes = []
unimplemented = []
empty_catches = []
force_unwraps = []

for df in dart_files:
    with open(df, encoding='utf-8') as f:
        lines = f.readlines()

    for idx, line in enumerate(lines):
        line_num = idx + 1
        clean = line.strip()

        if '// TODO' in clean or '// todo' in clean.lower():
            todos.append((df, line_num, clean))
        if '// FIXME' in clean or '// fixme' in clean.lower():
            fixmes.append((df, line_num, clean))
        if 'throw UnimplementedError' in clean or 'UnimplementedError()' in clean:
            unimplemented.append((df, line_num, clean))
        if re.search(r'catch\s*\([^)]*\)\s*\{\s*\}', clean):
            empty_catches.append((df, line_num, clean))

print(f'=== TOTAL DART FILES AUDITED: {len(dart_files)} ===')
print(f'TODOs found: {len(todos)}')
for t in todos[:10]:
    print(f'  {t[0]}:{t[1]} -> {t[2]}')

print(f'\nFIXMEs found: {len(fixmes)}')
for f in fixmes[:10]:
    print(f'  {f[0]}:{f[1]} -> {f[2]}')

print(f'\nUnimplemented Errors found: {len(unimplemented)}')
for u in unimplemented[:10]:
    print(f'  {u[0]}:{u[1]} -> {u[2]}')

print(f'\nSilent Empty Catches found: {len(empty_catches)}')
for c in empty_catches[:10]:
    print(f'  {c[0]}:{c[1]} -> {c[2]}')
