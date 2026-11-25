// Local check of backup / delete / restore against the Firebase emulators:
//   firebase emulators:exec --only auth,firestore,functions --project demo-mnfamily "node functions/emulator_vault_test.mjs"
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const PROJECT = process.env.GCLOUD_PROJECT || 'demo-mnfamily';
process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';
if (!PROJECT.startsWith('demo-')) throw new Error('Use a demo- project id with the emulators');
const FN = `http://127.0.0.1:5001/${PROJECT}/asia-south1`;
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
initializeApp({ projectId: PROJECT });
const db = getFirestore();

let failures = 0;
const ok = (c, m) => { console.log(`${c ? 'PASS' : 'FAIL'}  ${m}`); if (!c) failures++; };
async function call(name, data, token) {
  const r = await fetch(`${FN}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data }),
  });
  const j = await r.json();
  return j.error ? { error: j.error } : j.result;
}
async function token(email, password) {
  const r = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  return (await r.json()).idToken;
}

// Seed
const when = Timestamp.fromDate(new Date('2026-11-20T10:00:00Z'));
await db.doc('users/ceoofmn@mnjpark.com').set({ empId: 'MN-CEO01', roleType: 'ceo', password: 'secret' });
await db.doc('users/staff@test.com').set({ empId: 'E1', roleType: 'employee', password: 'secret' });
await db.doc('online_department_employees/E1').set({
  name: 'Test Staff', email: 'staff@test.com', password: 'secret',
  fourPillars: { health: { steps: 4000 }, family: { hours: 2 } },
});
await db.doc('departments/online').set({ name: 'Online' });
await db.doc('konar_books/online_department').set({ title: 'Handbook' });
await db.doc('konar_books/online_department/pdf_chunks/0').set({ data: 'x'.repeat(1000) });
await db.doc('social_causes/S1').set({ title: 'Food donation', amountSpent: 500, date: when });
await db.doc('company_notifications/N1').set({ title: 'Hello', timestamp: when });
await db.doc('mn_team_chats/C1').set({ text: 'hi', senderId: 'E1' });
await db.doc('monthly_scorecards/2026-11').set({ month: 11 });
await db.doc('monthly_scorecards/2026-11/rows/r1').set({ score: 9 });
await db.doc('password_resets/P1').set({ codeHash: 'abc' });
await getAuth().createUser({ email: 'ceoofmn@mnjpark.com', password: 'ceopass1' });
await getAuth().createUser({ email: 'staff@test.com', password: 'staffpass' });
const ceo = await token('ceoofmn@mnjpark.com', 'ceopass1');
const staff = await token('staff@test.com', 'staffpass');

// Only the CEO
ok((await call('exportBackup', {}, staff)).error?.status === 'PERMISSION_DENIED', 'staff cannot export');
ok((await call('exportBackup', {})).error?.status === 'UNAUTHENTICATED', 'signed-out caller cannot export');
ok((await call('wipeOperationalData', { confirm: 'DELETE' }, staff)).error?.status === 'PERMISSION_DENIED', 'staff cannot delete');

// Backup
const backup = await call('exportBackup', {}, ceo);
const text = JSON.stringify(backup);
ok(backup.format === 'mn-family-backup', 'backup has the right format');
ok(backup.counts.social_causes === 1 && backup.counts.mn_team_chats === 1, 'backup counts collections');
ok(!text.includes('"password"') && !text.includes('secret'), 'no passwords in the backup');
ok(!('password_resets' in backup.collections), 'no reset secrets in the backup');
ok(!text.includes('pdf_chunks'), 'Konar PDF chunks left out');
ok(backup.collections.monthly_scorecards[0].subcollections?.rows?.length === 1, 'sub-collections included');
ok(backup.collections.social_causes[0].data.date.__type === 'timestamp', 'dates kept as timestamps');

// Delete
ok((await call('wipeOperationalData', {}, ceo)).error?.status === 'FAILED_PRECONDITION', 'delete needs typed confirmation');
const wiped = await call('wipeOperationalData', { confirm: 'DELETE' }, ceo);
ok(wiped.ok && wiped.deleted.social_causes === 1, 'delete reports what it removed');
ok((await db.collection('social_causes').get()).empty, 'social causes deleted');
ok((await db.collection('company_notifications').get()).empty, 'notifications deleted');
ok((await db.collection('mn_team_chats').get()).empty, 'chats deleted');
ok((await db.collection('monthly_scorecards/2026-11/rows').get()).empty, 'sub-collections deleted');
ok((await db.doc('users/staff@test.com').get()).exists, 'logins kept');
const emp = await db.doc('online_department_employees/E1').get();
ok(emp.exists && emp.get('name') === 'Test Staff' && emp.get('email') === 'staff@test.com', 'staff details kept');
ok(emp.get('fourPillars') === undefined, 'pillar activity cleared from profiles');
ok((await db.doc('konar_books/online_department/pdf_chunks/0').get()).exists, 'Konar handbook kept');
ok((await db.doc('departments/online').get()).exists, 'departments kept');

// Restore
ok((await call('restoreBackup', { backup: { hello: 1 } }, ceo)).error?.status === 'INVALID_ARGUMENT', 'rejects a non-backup file');
await db.doc('online_department_employees/E1').update({ name: 'Renamed Later' });
const restored = await call('restoreBackup', { backup }, ceo);
ok(restored.ok && restored.restored.social_causes === 1, 'restore reports counts');
const sc = await db.doc('social_causes/S1').get();
ok(sc.exists && sc.get('date') instanceof Timestamp && sc.get('date').toMillis() === when.toMillis(), 'social cause back with its date');
ok((await db.doc('monthly_scorecards/2026-11/rows/r1').get()).exists, 'sub-collections back');
const emp2 = await db.doc('online_department_employees/E1').get();
ok(emp2.get('fourPillars')?.health?.steps === 4000, 'pillar activity back on the profile');
ok(emp2.get('name') === 'Renamed Later', 'newer staff details not overwritten');
ok(emp2.get('password') === 'secret', 'restore does not touch login fields');

console.log(failures ? `\n${failures} FAILED` : '\nALL PASSED');
process.exit(failures ? 1 : 0);
