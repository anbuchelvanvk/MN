import re
import glob
import os

html_files = glob.glob('*.html')
for hf in sorted(html_files):
    with open(hf, encoding='utf-8') as f:
        content = f.read()

    # Find all inline on* handlers
    handlers = re.findall(r'on[a-z]+\s*=\s*["\']([^"\']+)["\']', content, re.IGNORECASE)

    # Find all getElementById calls
    get_ids = re.findall(r'document\.getElementById\(["\']([^"\']+)["\']\)', content)

    # Find querySelector with #id
    qs_ids = re.findall(r'querySelector\(["\']#([^"\'>.\s]+)["\']\)', content)
    all_requested_ids = set(get_ids + qs_ids)

    # Find all id attributes
    defined_ids = set(re.findall(r'\bid\s*=\s*["\']([^"\']+)["\']', content, re.IGNORECASE))

    missing_ids = [gid for gid in all_requested_ids if gid not in defined_ids]

    # Find all function definitions in the file
    func_defs = set(re.findall(r'function\s+([a-zA-Z0-9_$]+)\s*\(', content))

    # Check for calls in on* handlers to see if function exists in file or ecosystem-data.js / app.js
    called_funcs = []
    for h in handlers:
        m = re.match(r'([a-zA-Z0-9_$]+)\s*\(', h.strip())
        if m:
            called_funcs.append(m.group(1))

    print(f'=== File: {hf} ===')
    print(f'  Defined IDs: {len(defined_ids)}')
    print(f'  getElementById/querySelector IDs: {len(all_requested_ids)}')
    print(f'  Missing IDs: {missing_ids}')
    print(f'  Functions defined: {len(func_defs)}')
    print(f'  Inline handler functions called: {len(set(called_funcs))}')
    print()
