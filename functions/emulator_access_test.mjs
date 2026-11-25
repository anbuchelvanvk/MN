// Local check of disableStaffLogin against the Firebase emulators:
//   firebase emulators:exec --only auth,firestore,functions --project demo-mnfamily "node functions/emulator_access_test.mjs"
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
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
async function signIn(email, password) {
  const r = await fetch(`${AUTH}/accounts:signInWithPassword?key=fake`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  return r.json();
}

await db.doc('users/hr@mnj.com').set({ empId: '7', roleType: 'hr' });
await db.doc('users/staff@test.com').set({ empId: 'E1', roleType: 'employee' });
await db.doc('users/other@test.com').set({ empId: 'E2', roleType: 'employee' });
await getAuth().createUser({ email: 'hr@mnj.com', password: 'hrpass12' });
await getAuth().createUser({ email: 'staff@test.com', password: 'staffpass' });
await getAuth().createUser({ email: 'other@test.com', password: 'otherpass' });
const hr = (await signIn('hr@mnj.com', 'hrpass12')).idToken;
const other = (await signIn('other@test.com', 'otherpass')).idToken;

ok((await call('disableStaffLogin', { email: 'staff@test.com' })).error?.status === 'PERMISSION_DENIED', 'signed-out caller refused');
ok((await call('disableStaffLogin', { email: 'staff@test.com' }, other)).error?.status === 'PERMISSION_DENIED', 'staff cannot switch others off');
ok((await call('disableStaffLogin', { email: 'ceoofmn@mnjpark.com' }, hr)).error?.status === 'FAILED_PRECONDITION', 'leadership cannot be switched off');
const res = await call('disableStaffLogin', { email: 'STAFF@test.com ' }, hr);
ok(res.ok === true, 'HR can switch a relieved person off');
ok((await getAuth().getUserByEmail('staff@test.com')).disabled === true, 'account is disabled');
const again = await signIn('staff@test.com', 'staffpass');
ok(String(again.error?.message || '').includes('USER_DISABLED'), 'relieved person can no longer sign in');
ok((await db.doc('relieved_staff/staff@test.com').get()).exists, 'record kept of who switched it off');
ok((await call('disableStaffLogin', { email: 'nobody@test.com' }, hr)).ok === true, 'person without a sign-in is fine');

console.log(failures ? `\n${failures} FAILED` : '\nALL PASSED');
process.exit(failures ? 1 : 0);
