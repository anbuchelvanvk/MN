import re

with open('lib/providers/ecosystem_provider.dart', encoding='utf-8') as f:
    text = f.read()

accounts_to_check = [
    ('CEO', 'ceoofmn@mnjpark.com', 'adminnaandhan'),
    ('HR', 'hr@mnj.com', 'hr@mnj123'),
    ('OTM', 'praveenkumarotm@mnj.com', 'praveen@mnj123'),
    ('OSH', 'gokulakrishnanosh@mnj.com', 'gokul@mnj123'),
    ('VPE', 'aravindasamyvpe@mnj.com', 'aravind@mnj123'),
    ('Ass.VPE', 'mithraassvpe@mnj.com', 'mithra@mnj123'),
    ('ECE', 'ece@mnj.com', 'ece@mnj123'),
    ('OS1', 'kaaviyaos1@mnj.com', 'kaaviya@mnj123'),
    ('OS2', 'nishaos2@mnj.com', 'nisha@mnj123'),
    ('AC', 'midhunkumarac@mnj.com', 'midhun@mnj123'),
    ('OSS', 'subashoss@mnj.com', 'subash@mnj123'),
    ('DVP', 'eshwardvp@mnj.com', 'eshwar@mnj123'),
    ('CC', 'samroycc@mnj.com', 'samroy@mnj123'),
]

print("=== Checking 13 Target Accounts in ecosystem_provider.dart ===")
for code, acc, pwd in accounts_to_check:
    acc_found = acc in text
    pwd_found = pwd in text
    print(f"[{code}] {acc} -> Email: {'YES' if acc_found else 'NO'}, Pwd: {'YES' if pwd_found else 'NO'}")

with open('lib/services/firebase_employee_service.dart', encoding='utf-8') as f:
    fb_text = f.read()

print("\n=== Checking 13 Target Accounts in firebase_employee_service.dart ===")
for code, acc, pwd in accounts_to_check:
    acc_found = acc in fb_text
    print(f"[{code}] {acc} -> in FirebaseService: {'YES' if acc_found else 'NO'}")

with open('lib/models/employee_model.dart', encoding='utf-8') as f:
    emp_model_text = f.read()

print(f"\nEmployeeModel lines: {len(emp_model_text.splitlines())}")
has_permissions = 'permissions' in emp_model_text.lower() or 'canaccess' in emp_model_text.lower()
print(f"EmployeeModel currently has permissions fields: {has_permissions}")
