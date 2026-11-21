import os
import re
import glob

def audit():
    print("=== 1. HOURS FORMATTING AUDIT ===")
    for f in glob.glob('lib/**/*.dart', recursive=True):
        with open(f, encoding='utf-8') as fp:
            lines = fp.readlines()
        for i, line in enumerate(lines):
            clean = line.strip()
            if re.search(r'\b0\.\d+h\b', clean) or re.search(r'0\.\d+\s*hrs?', clean) or '0.8' in clean:
                print(f"{f}:{i+1}: {clean[:100]}")
            if ('formatHours' in clean or 'formatDuration' in clean or 'formatTime' in clean) and 'def' not in clean:
                print(f"  [Formatter] {f}:{i+1}: {clean[:100]}")

    print("\n=== 2. CEO ACTIONS VS HR ACTIONS AUDIT ===")
    with open('lib/views/hr/hr_portal_screen.dart', encoding='utf-8') as f:
        hr_text = f.read()
    with open('lib/views/ceo/ceo_suite_screen.dart', encoding='utf-8') as f:
        ceo_text = f.read()

    # Look for navigation targets / subpages in HR
    hr_targets = set(re.findall(r'MaterialPageRoute\(builder:\s*\(_\)\s*=>\s*(?:const\s+)?(\w+)\(', hr_text))
    ceo_targets = set(re.findall(r'MaterialPageRoute\(builder:\s*\(_\)\s*=>\s*(?:const\s+)?(\w+)\(', ceo_text))

    print(f"HR Nav Targets ({len(hr_targets)}):", sorted(hr_targets))
    print(f"CEO Nav Targets ({len(ceo_targets)}):", sorted(ceo_targets))
    missing_in_ceo = hr_targets - ceo_targets
    print(f"HR features not directly in CEO nav ({len(missing_in_ceo)}):", sorted(missing_in_ceo))

    print("\n=== 3. ANNIVERSARY LOGIC & NOTIFICATIONS ===")
    for f in glob.glob('lib/**/*.dart', recursive=True):
        with open(f, encoding='utf-8') as fp:
            lines = fp.readlines()
        for i, line in enumerate(lines):
            clean = line.strip()
            if 'anniversary' in clean.lower():
                if any(k in clean.lower() for k in ['notify', 'broadcast', 'single', 'dialog', 'check', 'milestone']):
                    print(f"{f}:{i+1}: {clean[:100]}")

    print("\n=== 4. DEPARTMENT DELETION & REALLOCATION ===")
    for f in glob.glob('lib/**/*.dart', recursive=True):
        with open(f, encoding='utf-8') as fp:
            lines = fp.readlines()
        for i, line in enumerate(lines):
            clean = line.strip()
            if any(k in clean.lower() for k in ['deletedepartment', 'reallocat', 'togglekonar', 'iskonarenabled']):
                print(f"{f}:{i+1}: {clean[:100]}")

if __name__ == '__main__':
    audit()
