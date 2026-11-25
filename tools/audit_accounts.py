import re

with open('lib/providers/ecosystem_provider.dart', encoding='utf-8') as f:
    text = f.read()

accounts_to_check = [
    ('CEO', 'ceoofmn@mnjpark.com'),
    ('HR', 'hr@mnj.com'),
    ('OTM', 'praveenkumarotm@mnj.com'),
    ('OSH', 'gokulakrishnanosh@mnj.com'),
    ('VPE', 'aravindasamyvpe@mnj.com'),
    ('Ass.VPE', 'mithraassvpe@mnj.com'),
    ('ECE', 'ece@mnj.com'),
    ('OS1', 'kaaviyaos1@mnj.com'),
    ('OS2', 'nishaos2@mnj.com'),
    ('AC', 'midhunkumarac@mnj.com'),
    ('OSS', 'subashoss@mnj.com'),
    ('DVP', 'eshwardvp@mnj.com'),
    ('CC', 'samroycc@mnj.com'),
]

# Passwords are never kept in this repo. Flag any password-like literal instead.
PASSWORD_PATTERN = re.compile(r"[a-z]+@mnj(park)?\d{3}")

print("=== Checking 13 Target Accounts in ecosystem_provider.dart ===")
for code, acc in accounts_to_check:
    acc_found = acc in text
    print(f"[{code}] {acc} -> Email: {'YES' if acc_found else 'NO'}")
leaks = PASSWORD_PATTERN.findall(text)
print(f"Hard-coded password-like strings: {'NONE' if not leaks else len(leaks)}")

with open('lib/services/firebase_employee_service.dart', encoding='utf-8') as f:
    fb_text = f.read()

print("\n=== Checking 13 Target Accounts in firebase_employee_service.dart ===")
for code, acc in accounts_to_check:
    acc_found = acc in fb_text
    print(f"[{code}] {acc} -> in FirebaseService: {'YES' if acc_found else 'NO'}")

with open('lib/models/employee_model.dart', encoding='utf-8') as f:
    emp_model_text = f.read()

print(f"\nEmployeeModel lines: {len(emp_model_text.splitlines())}")
has_permissions = 'permissions' in emp_model_text.lower() or 'canaccess' in emp_model_text.lower()
print(f"EmployeeModel currently has permissions fields: {has_permissions}")
