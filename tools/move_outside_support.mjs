// Moves the outside support people (EXT-* ids) into one collection,
// "external_support_employees", with dept "External Support Staff [Online]",
// so the app loads and labels them properly.
//
//   node tools/move_outside_support.mjs           (dry run: shows what would move)
//   node tools/move_outside_support.mjs --apply   (backs up, then moves)
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

const TARGET = 'external_support_employees';
const DEPT = 'External Support Staff [Online]';
const apply = process.argv.includes('--apply');

initializeApp({ credential: cert(require(join(here, 'service-account.json'))) });
const db = getFirestore();

const sources = (await db.listCollections())
  .map((c) => c.id)
  .filter((id) => id.endsWith('_employees') && id !== TARGET);

const moves = [];
for (const col of sources) {
  const snap = await db.collection(col).get();
  for (const doc of snap.docs) {
    if (doc.id.toUpperCase().startsWith('EXT-')) moves.push({ col, id: doc.id, data: doc.data() });
  }
}

if (!moves.length) {
  console.log('Nothing to move: outside support is already in place.');
  process.exit(0);
}
for (const m of moves) console.log(`${m.col}/${m.id}  (${m.data.name ?? '?'})  ->  ${TARGET}/${m.id}`);
if (!apply) {
  console.log(`\nDry run. ${moves.length} record(s) would move. Run with --apply to move them.`);
  process.exit(0);
}

const backupDir = join(here, 'backups');
mkdirSync(backupDir, { recursive: true });
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
const backupFile = join(backupDir, `outside_support_before_move_${stamp}.json`);
writeFileSync(backupFile, JSON.stringify(moves, null, 2));
console.log(`\nBackup written: ${backupFile}`);

for (const m of moves) {
  const target = db.collection(TARGET).doc(m.id);
  const existing = await target.get();
  // Keep any newer copy already in the target; fill in what is missing.
  const merged = { ...m.data, ...(existing.exists ? existing.data() : {}), dept: DEPT };
  await target.set(merged, { merge: true });
  await db.collection(m.col).doc(m.id).delete();
  const email = merged.email;
  if (email) {
    const user = db.collection('users').doc(email);
    if ((await user.get()).exists) await user.set({ dept: DEPT }, { merge: true });
  }
  console.log(`Moved ${m.id}`);
}
console.log(`\nDone. ${moves.length} record(s) now in ${TARGET}.`);
