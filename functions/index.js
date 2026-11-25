// MN Family — HR-verified password reset.
//
// Flow
//   1. Staff member (signed out) taps "Forgot password" and enters their email.
//      requestPasswordReset creates a request and returns a 5-character code
//      plus a private resume token to that phone only.
//   2. They tell the code to HR in person / on a call.
//   3. HR (or the CEO) opens "Password requests" in the app and types the code
//      against that person: hrVerifyPasswordReset approves the request.
//   4. The staff member's phone sees the approval (getPasswordResetStatus) and
//      shows a "set new password" form: completePasswordReset sets it.
//
// The code and token are stored only as SHA-256 hashes in password_resets/,
// which clients can never read (see firestore.rules). HR sees only the
// password_reset_queue/ summary (who asked, when, status) — never the code.

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const crypto = require('crypto');

initializeApp();
setGlobalOptions({ region: 'asia-south1', maxInstances: 5 });

const db = getFirestore();
const LEADERSHIP = { 'ceoofmn@mnjpark.com': 'ceo', 'hr@mnj.com': 'hr' };
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O, 1/I
const CODE_TTL_MS = 30 * 60 * 1000; // code valid 30 minutes
const APPROVAL_TTL_MS = 20 * 60 * 1000; // after approval, 20 minutes to set it
const MAX_ATTEMPTS = 5;

const sha = (s) => crypto.createHash('sha256').update(String(s)).digest('hex');
const now = () => Date.now();

function newCode() {
  const bytes = crypto.randomBytes(5);
  let out = '';
  for (let i = 0; i < 5; i++) out += CODE_ALPHABET[bytes[i] % CODE_ALPHABET.length];
  return out;
}

function cleanEmail(v) {
  return String(v || '').trim().toLowerCase();
}

async function callerRole(auth) {
  if (!auth || !auth.token || !auth.token.email) return null;
  const email = cleanEmail(auth.token.email);
  if (LEADERSHIP[email]) return LEADERSHIP[email];
  const snap = await db.collection('users').doc(email).get();
  return snap.exists ? String(snap.get('roleType') || 'employee').toLowerCase() : null;
}

/** Step 1: staff member asks for a reset. No sign-in needed. */
exports.requestPasswordReset = onCall(async (req) => {
  const email = cleanEmail(req.data && req.data.email);
  if (!email || !email.includes('@')) {
    throw new HttpsError('invalid-argument', 'Enter your official email address.');
  }
  const userDoc = await db.collection('users').doc(email).get();
  if (!userDoc.exists) {
    throw new HttpsError('not-found', 'No staff account uses this email. Check it or ask HR.');
  }

  // One live request per person: cancel older pending ones.
  const open = await db
    .collection('password_resets')
    .where('email', '==', email)
    .where('status', 'in', ['pending', 'approved'])
    .get();
  const recent = open.docs.find((d) => now() - (d.get('createdAt') || 0) < 60 * 1000);
  if (recent) {
    throw new HttpsError('resource-exhausted', 'A code was just created. Please wait a minute before asking again.');
  }
  const batch = db.batch();
  open.docs.forEach((d) => {
    batch.update(d.ref, { status: 'cancelled' });
    batch.set(db.collection('password_reset_queue').doc(d.id), { status: 'cancelled' }, { merge: true });
  });

  const code = newCode();
  const token = crypto.randomBytes(24).toString('hex');
  const ref = db.collection('password_resets').doc();
  const createdAt = now();
  const expiresAt = createdAt + CODE_TTL_MS;
  const name = String(userDoc.get('name') || userDoc.get('displayName') || email.split('@')[0]);
  const empId = String(userDoc.get('empId') || '');

  batch.set(ref, {
    email,
    empId,
    name,
    codeHash: sha(`${ref.id}:${code}`),
    tokenHash: sha(token),
    status: 'pending',
    attempts: 0,
    createdAt,
    expiresAt,
  });
  batch.set(db.collection('password_reset_queue').doc(ref.id), {
    email,
    empId,
    name,
    status: 'pending',
    createdAt,
    expiresAt,
  });
  await batch.commit();

  return { requestId: ref.id, code, token, expiresAt, name };
});

/** Step 3: HR / CEO types the code the staff member read out. */
exports.hrVerifyPasswordReset = onCall(async (req) => {
  const role = await callerRole(req.auth);
  if (role !== 'hr' && role !== 'ceo') {
    throw new HttpsError('permission-denied', 'Only HR or the CEO can approve password resets.');
  }
  const requestId = String((req.data && req.data.requestId) || '');
  const code = String((req.data && req.data.code) || '').trim().toUpperCase();
  if (!requestId || code.length !== 5) {
    throw new HttpsError('invalid-argument', 'Enter the 5-character code.');
  }

  const ref = db.collection('password_resets').doc(requestId);
  const queueRef = db.collection('password_reset_queue').doc(requestId);
  const approver = cleanEmail(req.auth.token.email);

  // Errors are returned from the transaction (not thrown inside it) so the
  // attempt counter / expiry status are actually committed.
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return { err: ['not-found', 'This request no longer exists.'] };
    const r = snap.data();
    if (r.status !== 'pending') {
      return { err: ['failed-precondition', `This request is already ${r.status}.`] };
    }
    if (now() > r.expiresAt) {
      tx.update(ref, { status: 'expired' });
      tx.set(queueRef, { status: 'expired' }, { merge: true });
      return { err: ['deadline-exceeded', 'This code has expired. Ask them to request a new one.'] };
    }
    if (sha(`${requestId}:${code}`) !== r.codeHash) {
      const attempts = (r.attempts || 0) + 1;
      const locked = attempts >= MAX_ATTEMPTS;
      tx.update(ref, { attempts, ...(locked ? { status: 'locked' } : {}) });
      if (locked) tx.set(queueRef, { status: 'locked' }, { merge: true });
      return {
        err: [
          'permission-denied',
          locked
            ? 'Too many wrong codes. This request is locked; ask them to start again.'
            : `That code does not match. ${MAX_ATTEMPTS - attempts} tries left.`,
        ],
      };
    }
    const approvedAt = now();
    const update = { status: 'approved', approvedBy: approver, approvedAt, expiresAt: approvedAt + APPROVAL_TTL_MS };
    tx.update(ref, update);
    tx.set(queueRef, update, { merge: true });
    return { ok: true, name: r.name, email: r.email };
  });
  if (result.err) throw new HttpsError(result.err[0], result.err[1]);
  return result;
});

async function loadOwnRequest(data) {
  const requestId = String((data && data.requestId) || '');
  const token = String((data && data.token) || '');
  if (!requestId || !token) throw new HttpsError('invalid-argument', 'Missing request details.');
  const ref = db.collection('password_resets').doc(requestId);
  const snap = await ref.get();
  if (!snap.exists || snap.get('tokenHash') !== sha(token)) {
    throw new HttpsError('not-found', 'This reset request was not found. Please start again.');
  }
  return { ref, r: snap.data(), requestId };
}

/** Step 4a: the staff member's phone checks whether HR has approved. */
exports.getPasswordResetStatus = onCall(async (req) => {
  const { ref, r, requestId } = await loadOwnRequest(req.data);
  let status = r.status;
  if ((status === 'pending' || status === 'approved') && now() > r.expiresAt) {
    status = 'expired';
    await ref.update({ status });
    await db.collection('password_reset_queue').doc(requestId).set({ status }, { merge: true });
  }
  return { status, expiresAt: r.expiresAt, approvedBy: r.approvedBy || null };
});

/** Step 4b: after approval, set the new password. */
exports.completePasswordReset = onCall(async (req) => {
  const { ref, r, requestId } = await loadOwnRequest(req.data);
  const password = String((req.data && req.data.newPassword) || '');
  if (r.status !== 'approved') {
    throw new HttpsError('failed-precondition', 'HR has not approved this request yet.');
  }
  if (now() > r.expiresAt) {
    await ref.update({ status: 'expired' });
    throw new HttpsError('deadline-exceeded', 'The approval has expired. Please start again.');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }

  let user;
  try {
    user = await getAuth().getUserByEmail(r.email);
  } catch (e) {
    throw new HttpsError('not-found', 'No login exists for this email yet. Ask HR to create it.');
  }
  await getAuth().updateUser(user.uid, { password });
  // Sign the account out everywhere else.
  await getAuth().revokeRefreshTokens(user.uid);

  const done = { status: 'completed', completedAt: now() };
  await ref.update(done);
  await db.collection('password_reset_queue').doc(requestId).set(done, { merge: true });
  return { ok: true, email: r.email };
});

// Company data backup / delete / restore (CEO only)
Object.assign(exports, require('./data_vault'));
