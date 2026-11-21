import re
import glob

# Read ecosystem-data.js and app.js
with open('ecosystem-data.js', encoding='utf-8') as f:
    eco_js = f.read()

with open('app.js', encoding='utf-8') as f:
    app_js = f.read()

# Collect all global functions & MNStore methods
eco_funcs = set(re.findall(r'function\s+([a-zA-Z0-9_$]+)\s*\(', eco_js))
app_funcs = set(re.findall(r'function\s+([a-zA-Z0-9_$]+)\s*\(', app_js))
store_methods = set(re.findall(r'\b([a-zA-Z0-9_$]+)\s*\([^)]*\)\s*\{', eco_js))

all_available = eco_funcs | app_funcs | store_methods

html_files = glob.glob('*.html')
for hf in sorted(html_files):
    with open(hf, encoding='utf-8') as f:
        content = f.read()

    file_funcs = set(re.findall(r'function\s+([a-zA-Z0-9_$]+)\s*\(', content))
    handlers = re.findall(r'on[a-z]+\s*=\s*["\']([^"\']+)["\']', content, re.IGNORECASE)

    missing = []
    for h in handlers:
        # Check standard func() calls
        m = re.match(r'([a-zA-Z0-9_$]+)\s*\(', h.strip())
        if m:
            fname = m.group(1)
            if fname not in file_funcs and fname not in all_available:
                missing.append((fname, h.strip()))

    print(f'File: {hf}')
    print(f'  Potentially missing functions: {missing}')
