// Puts the CEO and HR in the "Administration Department" and removes the
// leftover stub copies of them from online_department_employees.
//
//   node tools/move_admin_department.mjs           (dry run)
//   node tools/move_admin_department.mjs --apply   (backs up, then changes)
//
// Needs tools/service-account.json (gitignored).
import { createRequire } from 'node:module';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(join(here, '..', 'functions', 'package.json'));
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const DEPT = 'Administration Department';
const ADMIN_COL = 'administration_employees';
const LEADERS = [
  { id: 'MN-CEO01', email: 'ceoofmn@mnjpark.com' },
  { id: '7', email: 'hr@mnj.com' },
];
const STUBS = ['7', 'MN-HR1001', 'MN-CEO01']; // copies in online_department_employees
const apply = process.argv.includes('--apply');

initializeApp({ credential: cert(require(join(here, 'service-account.json'))) });
const db = getFirestore();

const backup = {};
const plan = [];
for (const { id, email } of LEADERS) {
  const doc = await db.doc(`${ADMIN_COL}/${id}`).get();
  if (!doc.exists) throw new Error(`${ADMIN_COL}/${id} is missing; not touching anything.`);
  backup[`${ADMIN_COL}/${id}`] = doc.data();
  if (doc.get('dept') !== DEPT) plan.push(`${ADMIN_COL}/${id}: dept "${doc.get('dept')}" -> "${DEPT}"`);
  const user = await db.doc(`users/${email}`).get();
  if (user.exists) {
    backup[`users/${email}`] = user.data();
    if (user.get('dept') !== DEPT) plan.push(`users/${email}: dept "${user.get('dept')}" -> "${DEPT}"`);
  }
}
for (const id of STUBS) {
  const stub = await db.doc(`online_department_employees/${id}`).get();
  if (stub.exists) {
    backup[`online_department_employees/${id}`] = stub.data();
    plan.push(`online_department_employees/${id}: delete leftover copy (${stub.get('name') ?? '?'})`);
  }
}

if (!plan.length) {
  console.log('Nothing to do: already in place.');
  process.exit(0);
}
plan.forEach((p) => console.log(p));
if (!apply) {
  console.log(`\nDry run. ${plan.length} change(s). Run with --apply to make them.`);
  process.exit(0);
}

mkdirSync(join(here, 'backups'), { recursive: true });
const file = join(here, 'backups', `admin_department_before_${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
writeFileSync(file, JSON.stringify(backup, null, 2));
console.log(`\nBackup written: ${file}`);

for (const { id, email } of LEADERS) {
  await db.doc(`${ADMIN_COL}/${id}`).set({ dept: DEPT }, { merge: true });
  const user = db.doc(`users/${email}`);
  if ((await user.get()).exists) await user.set({ dept: DEPT, collection: ADMIN_COL }, { merge: true });
}
for (const id of STUBS) {
  await db.doc(`online_department_employees/${id}`).delete();
}
await db.doc(`departments/${ADMIN_COL}`).set({ name: DEPT, collection: ADMIN_COL }, { merge: true });
console.log('Done.');
