// Local end-to-end check of the HR-verified password reset, against the
// Firebase emulators only (auth + firestore + functions). Run with:
//   firebase emulators:exec --only auth,firestore,functions --project demo-mnfamily "node functions/emulator_flow_test.mjs"
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const PROJECT = process.env.GCLOUD_PROJECT || 'demo-mnfamily';
const FN = `http://127.0.0.1:5001/${PROJECT}/asia-south1`;
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
// Always talk to the local emulators, never the real project.
process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ||= '127.0.0.1:9099';
if (!PROJECT.startsWith('demo-')) throw new Error('Use a demo- project id with the emulators');
initializeApp({ projectId: PROJECT });
const db = getFirestore();

let failures = 0;
const ok = (cond, msg) => { console.log(`${cond ? 'PASS' : 'FAIL'}  ${msg}`); if (!cond) failures++; };

async function call(name, data, idToken) {
  const r = await fetch(`${FN}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(idToken ? { Authorization: `Bearer ${idToken}` } : {}) },
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

// Seed: a staff member, HR, and another employee
await db.doc('users/staff@test.com').set({ empId: 'E1', roleType: 'employee', name: 'Test Staff' });
await db.doc('users/hr@mnj.com').set({ empId: 'HR1', roleType: 'hr', name: 'HR Person' });
await db.doc('users/peer@test.com').set({ empId: 'E2', roleType: 'employee', name: 'Peer' });
await getAuth().createUser({ email: 'staff@test.com', password: 'oldpass1' });
await getAuth().createUser({ email: 'hr@mnj.com', password: 'hrpass1' });
await getAuth().createUser({ email: 'peer@test.com', password: 'peerpass1' });
const hrToken = (await signIn('hr@mnj.com', 'hrpass1')).idToken;
const peerToken = (await signIn('peer@test.com', 'peerpass1')).idToken;

// Unknown email is rejected
ok((await call('requestPasswordReset', { email: 'nobody@test.com' })).error?.status === 'NOT_FOUND', 'unknown email rejected');

// 1. Staff requests a code
const req = await call('requestPasswordReset', { email: 'Staff@Test.com ' });
ok(/^[A-HJ-NP-Z2-9]{5}$/.test(req.code || ''), `5-character code issued (${req.code})`);
const stored = (await db.doc(`password_resets/${req.requestId}`).get()).data();
ok(stored && !JSON.stringify(stored).includes(req.code) && !JSON.stringify(stored).includes(req.token), 'code and token stored only as hashes');
const queued = (await db.doc(`password_reset_queue/${req.requestId}`).get()).data();
ok(queued?.status === 'pending' && !('codeHash' in queued), 'HR queue entry has no code');

// Spamming a second request within a minute is refused
ok((await call('requestPasswordReset', { email: 'staff@test.com' })).error?.status === 'RESOURCE_EXHAUSTED', 'rapid repeat request refused');

// Cannot complete before approval
ok((await call('completePasswordReset', { requestId: req.requestId, token: req.token, newPassword: 'newpass1' })).error?.status === 'FAILED_PRECONDITION', 'cannot set password before HR approves');

// Non-HR cannot verify; unauthenticated cannot verify
ok((await call('hrVerifyPasswordReset', { requestId: req.requestId, code: req.code }, peerToken)).error?.status === 'PERMISSION_DENIED', 'employee cannot approve');
ok((await call('hrVerifyPasswordReset', { requestId: req.requestId, code: req.code })).error?.status === 'PERMISSION_DENIED', 'signed-out caller cannot approve');

// Wrong code counts an attempt
const wrong = await call('hrVerifyPasswordReset', { requestId: req.requestId, code: req.code === 'AAAAA' ? 'BBBBB' : 'AAAAA' }, hrToken);
ok(wrong.error?.status === 'PERMISSION_DENIED' && /4 tries left/.test(wrong.error.message), 'wrong code rejected with tries left');

// Status still pending; wrong token can't read it
ok((await call('getPasswordResetStatus', { requestId: req.requestId, token: req.token })).status === 'pending', 'status pending');
ok((await call('getPasswordResetStatus', { requestId: req.requestId, token: 'bad' })).error?.status === 'NOT_FOUND', 'wrong token cannot read status');

// 3. HR enters the right code (lower-case also accepted)
const v = await call('hrVerifyPasswordReset', { requestId: req.requestId, code: req.code.toLowerCase() }, hrToken);
ok(v.ok === true && v.name === 'Test Staff', 'HR verifies with correct code');
ok((await call('getPasswordResetStatus', { requestId: req.requestId, token: req.token })).status === 'approved', 'status approved');

// Wrong token cannot complete; short password refused
ok((await call('completePasswordReset', { requestId: req.requestId, token: 'bad', newPassword: 'newpass1' })).error?.status === 'NOT_FOUND', 'wrong token cannot set password');
ok((await call('completePasswordReset', { requestId: req.requestId, token: req.token, newPassword: '123' })).error?.status === 'INVALID_ARGUMENT', 'short password refused');

// 4. Staff sets the new password
const done = await call('completePasswordReset', { requestId: req.requestId, token: req.token, newPassword: 'newpass1' });
ok(done.ok === true, 'password set');
ok(!!(await signIn('staff@test.com', 'newpass1')).idToken, 'can sign in with new password');
ok(!(await signIn('staff@test.com', 'oldpass1')).idToken, 'old password no longer works');
ok((await call('completePasswordReset', { requestId: req.requestId, token: req.token, newPassword: 'again11' })).error?.status === 'FAILED_PRECONDITION', 'request cannot be reused');
ok((await db.doc(`password_reset_queue/${req.requestId}`).get()).data().status === 'completed', 'queue marked completed');

// Lock after 5 wrong attempts
await db.doc(`password_resets/${req.requestId}`).update({ createdAt: 0 });
const r2 = await call('requestPasswordReset', { email: 'peer@test.com' });
for (let i = 0; i < 5; i++) await call('hrVerifyPasswordReset', { requestId: r2.requestId, code: 'ZZZZZ' === r2.code ? 'YYYYY' : 'ZZZZZ' }, hrToken);
ok((await call('getPasswordResetStatus', { requestId: r2.requestId, token: r2.token })).status === 'locked', 'locked after 5 wrong codes');
ok((await call('hrVerifyPasswordReset', { requestId: r2.requestId, code: r2.code }, hrToken)).error?.status === 'FAILED_PRECONDITION', 'locked request cannot be approved even with right code');

console.log(failures ? `\n${failures} FAILED` : '\nALL PASSED');
process.exit(failures ? 1 : 0);
