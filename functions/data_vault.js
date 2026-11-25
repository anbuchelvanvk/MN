// MN Family — company data backup, delete and restore (CEO only).
//
// exportBackup      -> returns the whole database as one JSON document
// wipeOperationalData -> deletes everything except staff details
// restoreBackup     -> writes a backup's activity data back
//
// Always kept (never deleted, never overwritten by a restore):
//   users/, every *_employees collection (staff details), departments,
//   system_metadata and the Konar handbooks.
// Never put in a backup file: passwords, password-reset secrets, and the
// Konar PDF chunks (handbooks are kept in the database instead).

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, Timestamp, GeoPoint, FieldValue } = require('firebase-admin/firestore');

const FORMAT = 'mn-family-backup';
const VERSION = 1;

const isStaffCollection = (id) => id === 'users' || id.endsWith('_employees');
const KEEP_ON_WIPE = new Set(['departments', 'deleted_departments', 'system_metadata', 'konar_books']);
const SKIP_IN_BACKUP = new Set(['password_resets']);
const SKIP_SUBCOLLECTIONS = new Set(['pdf_chunks']);
const SECRET_KEYS = new Set(['password', 'passwordHash', 'tokenHash', 'codeHash']);

/** Fields on staff profiles that hold activity, not personal details. */
const ACTIVITY_FIELDS = ['fourPillars'];

function db() {
  return getFirestore();
}

async function requireCeo(auth) {
  const email = String((auth && auth.token && auth.token.email) || '').toLowerCase();
  if (!email) throw new HttpsError('unauthenticated', 'Please sign in again.');
  if (email === 'ceoofmn@mnjpark.com') return email;
  const snap = await db().collection('users').doc(email).get();
  if (snap.exists && String(snap.get('roleType') || '').toLowerCase() === 'ceo') return email;
  throw new HttpsError('permission-denied', 'Only the CEO can back up, delete or restore company data.');
}

// ------------------------------------------------------------ (de)serialise
function encode(v) {
  if (v === null || v === undefined) return null;
  if (v instanceof Timestamp) return { __type: 'timestamp', value: v.toDate().toISOString() };
  if (v instanceof GeoPoint) return { __type: 'geopoint', lat: v.latitude, lng: v.longitude };
  if (Buffer.isBuffer(v)) return { __type: 'bytes', base64: v.toString('base64') };
  if (v && typeof v === 'object' && typeof v.path === 'string' && typeof v.firestore === 'object') {
    return { __type: 'ref', path: v.path };
  }
  if (Array.isArray(v)) return v.map(encode);
  if (typeof v === 'object') {
    const out = {};
    for (const [k, val] of Object.entries(v)) {
      if (SECRET_KEYS.has(k)) continue;
      out[k] = encode(val);
    }
    return out;
  }
  return v;
}

function decode(v) {
  if (v === null || v === undefined) return null;
  if (Array.isArray(v)) return v.map(decode);
  if (typeof v === 'object') {
    switch (v.__type) {
      case 'timestamp':
        return Timestamp.fromDate(new Date(v.value));
      case 'geopoint':
        return new GeoPoint(v.lat, v.lng);
      case 'bytes':
        return Buffer.from(v.base64, 'base64');
      case 'ref':
        return db().doc(v.path);
      default: {
        const out = {};
        for (const [k, val] of Object.entries(v)) {
          if (SECRET_KEYS.has(k)) continue;
          out[k] = decode(val);
        }
        return out;
      }
    }
  }
  return v;
}

async function dumpCollection(colRef) {
  const snap = await colRef.get();
  const docs = [];
  for (const d of snap.docs) {
    const entry = { id: d.id, data: encode(d.data()) };
    const subs = (await d.ref.listCollections()).filter((s) => !SKIP_SUBCOLLECTIONS.has(s.id));
    if (subs.length) {
      entry.subcollections = {};
      for (const s of subs) entry.subcollections[s.id] = await dumpCollection(s);
    }
    docs.push(entry);
  }
  return docs;
}

/** Download everything as one backup document. */
exports.exportBackup = onCall({ timeoutSeconds: 300, memory: '512MiB' }, async (req) => {
  const by = await requireCeo(req.auth);
  const collections = {};
  const counts = {};
  for (const col of await db().listCollections()) {
    if (SKIP_IN_BACKUP.has(col.id)) continue;
    collections[col.id] = await dumpCollection(col);
    counts[col.id] = collections[col.id].length;
  }
  return {
    format: FORMAT,
    version: VERSION,
    createdAt: new Date().toISOString(),
    createdBy: by,
    project: process.env.GCLOUD_PROJECT || '',
    counts,
    collections,
  };
});

/** Delete everything except staff details (and the kept collections above). */
exports.wipeOperationalData = onCall({ timeoutSeconds: 540, memory: '512MiB' }, async (req) => {
  await requireCeo(req.auth);
  const data = req.data || {};
  if (data.confirm !== 'DELETE') {
    throw new HttpsError('failed-precondition', 'Type DELETE to confirm.');
  }
  const includeActivity = data.includeActivity !== false;
  const deleted = {};
  for (const col of await db().listCollections()) {
    if (isStaffCollection(col.id) || KEEP_ON_WIPE.has(col.id)) continue;
    const n = (await col.count().get()).data().count;
    await db().recursiveDelete(col);
    deleted[col.id] = n;
  }
  let profilesCleared = 0;
  if (includeActivity) {
    const writer = db().bulkWriter();
    for (const col of await db().listCollections()) {
      if (!col.id.endsWith('_employees')) continue;
      const snap = await col.get();
      for (const d of snap.docs) {
        const patch = {};
        for (const f of ACTIVITY_FIELDS) if (d.get(f) !== undefined) patch[f] = FieldValue.delete();
        if (Object.keys(patch).length) {
          writer.update(d.ref, patch);
          profilesCleared++;
        }
      }
    }
    await writer.close();
  }
  return { ok: true, deleted, profilesCleared };
});

async function writeDocs(colRef, docs, writer, tally) {
  for (const entry of docs || []) {
    const ref = colRef.doc(String(entry.id));
    writer.set(ref, decode(entry.data || {}), { merge: true });
    tally.docs++;
    for (const [sub, subDocs] of Object.entries(entry.subcollections || {})) {
      if (SKIP_SUBCOLLECTIONS.has(sub)) continue;
      await writeDocs(ref.collection(sub), subDocs, writer, tally);
    }
  }
}

/** Write a backup's activity data back. Staff details are never overwritten. */
exports.restoreBackup = onCall({ timeoutSeconds: 540, memory: '512MiB' }, async (req) => {
  await requireCeo(req.auth);
  const backup = req.data && req.data.backup;
  if (!backup || backup.format !== FORMAT || typeof backup.collections !== 'object') {
    throw new HttpsError('invalid-argument', 'This is not an MN Family backup file.');
  }
  const includeActivity = req.data.includeActivity !== false;
  const writer = db().bulkWriter();
  const restored = {};
  let profilesRestored = 0;

  for (const [colId, docs] of Object.entries(backup.collections)) {
    if (SKIP_IN_BACKUP.has(colId)) continue;
    if (isStaffCollection(colId)) {
      if (!includeActivity || colId === 'users') continue;
      // Only put activity back onto staff profiles that still exist.
      for (const entry of docs || []) {
        const ref = db().collection(colId).doc(String(entry.id));
        const snap = await ref.get();
        if (!snap.exists) continue;
        const patch = {};
        for (const f of ACTIVITY_FIELDS) {
          if (entry.data && entry.data[f] !== undefined) patch[f] = decode(entry.data[f]);
        }
        if (Object.keys(patch).length) {
          writer.set(ref, patch, { merge: true });
          profilesRestored++;
        }
      }
      continue;
    }
    const tally = { docs: 0 };
    await writeDocs(db().collection(colId), docs, writer, tally);
    restored[colId] = tally.docs;
  }
  await writer.close();
  return { ok: true, restored, profilesRestored };
});
