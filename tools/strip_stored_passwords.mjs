// Removes plain-text `password` fields that older app versions saved in
// Firestore (users/ and *_employees docs). Logins are handled by Firebase
// Authentication and do not need them.
//
//   node strip_stored_passwords.mjs          -> dry run: lists what would change
//   node strip_stored_passwords.mjs --apply  -> removes the fields
//
// Needs tools/service-account.json (git-ignored). Never prints passwords.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import admin from 'firebase-admin';

const here = dirname(fileURLToPath(import.meta.url));
const sa = JSON.parse(readFileSync(join(here, 'service-account.json'), 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();
const apply = process.argv.includes('--apply');
const SECRET = new Set(['password', 'plainPassword', 'tempPassword', 'defaultPassword']);

function secretPaths(obj, prefix = '') {
  const out = [];
  if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return out;
  for (const [k, v] of Object.entries(obj)) {
    const p = prefix ? `${prefix}.${k}` : k;
    if (SECRET.has(k) && (typeof v === 'string' || v === null)) out.push(p);
    else if (v && typeof v === 'object' && !Array.isArray(v) && !(v instanceof admin.firestore.Timestamp)) out.push(...secretPaths(v, p));
  }
  return out;
}

let docs = 0, fields = 0;
const writer = apply ? db.bulkWriter() : null;
for (const col of await db.listCollections()) {
  if (col.id === 'password_resets') continue; // hashes only, managed by Cloud Functions
  const snap = await col.get();
  for (const d of snap.docs) {
    const paths = secretPaths(d.data());
    if (!paths.length) continue;
    docs++; fields += paths.length;
    console.log(`${apply ? 'removing' : 'would remove'}  ${d.ref.path}  ->  ${paths.join(', ')}`);
    if (apply) {
      const patch = {};
      for (const p of paths) patch[p] = admin.firestore.FieldValue.delete();
      writer.update(d.ref, patch);
    }
  }
}
if (writer) await writer.close();
console.log(`\n${apply ? 'Removed' : 'Found'} ${fields} password field(s) in ${docs} document(s).`);
process.exit(0);
