// Sets new Firebase Auth passwords for MN Family staff accounts.
//
// Run this yourself; it needs admin rights on the "mn-family" project.
//
//  1. Firebase console -> Project settings -> Service accounts ->
//     "Generate new private key". Save the JSON as tools/service-account.json
//     (git-ignored; never commit or share it).
//  2. Create tools/staff_passwords.csv (git-ignored) with one line per account:
//         email,newPassword
//     e.g.  kaaviyaos1@mnj.com,<new password>
//  3. From the project folder:
//         cd tools
//         npm install firebase-admin@12
//         node set_staff_passwords.mjs
//  4. Delete staff_passwords.csv afterwards, and revoke the service-account key
//     in the console if you no longer need it.
//
// By default the script only changes the password of accounts that already
// exist. Staff who were added to the database but never got a Firebase login
// show "auth/user-not-found"; to create their logins, run:
//         node set_staff_passwords.mjs --create-missing
// Only emails that have a staff record in the users/ collection are created.
// The script never prints passwords.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import admin from 'firebase-admin';

const here = dirname(fileURLToPath(import.meta.url));
const serviceAccount = JSON.parse(readFileSync(join(here, 'service-account.json'), 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const lines = readFileSync(join(here, 'staff_passwords.csv'), 'utf8')
  .split(/\r?\n/)
  .map((l) => l.trim())
  .filter((l) => l && !l.startsWith('#') && l.toLowerCase() !== 'email,newpassword');

const createMissing = process.argv.includes('--create-missing');

let ok = 0;
let created = 0;
let failed = 0;
for (const line of lines) {
  const comma = line.indexOf(',');
  const email = line.slice(0, comma).trim().toLowerCase();
  const password = line.slice(comma + 1).trim();
  if (comma < 1 || password.length < 6) {
    console.log(`SKIP  ${email || line}: password must be at least 6 characters`);
    failed++;
    continue;
  }
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password });
    // Sign the account out everywhere so the old password stops working.
    await admin.auth().revokeRefreshTokens(user.uid);
    console.log(`OK    ${email}`);
    ok++;
  } catch (e) {
    if (e.code === 'auth/user-not-found' && createMissing) {
      try {
        // Only create logins for real staff (must have a users/{email} record)
        const staffDoc = await admin.firestore().collection('users').doc(email).get();
        if (!staffDoc.exists) {
          console.log(`SKIP  ${email}: no staff record in users/ - not creating a login`);
          failed++;
          continue;
        }
        const name = staffDoc.get('name');
        await admin.auth().createUser({
          email,
          password,
          ...(typeof name === 'string' && name ? { displayName: name } : {}),
        });
        console.log(`NEW   ${email} (login created)`);
        created++;
      } catch (e2) {
        console.log(`FAIL  ${email}: ${e2.code || e2.message}`);
        failed++;
      }
      continue;
    }
    const hint = e.code === 'auth/user-not-found' ? ' (no login yet - re-run with --create-missing)' : '';
    console.log(`FAIL  ${email}: ${e.code || e.message}${hint}`);
    failed++;
  }
}
console.log(`\n${ok} updated, ${created} created, ${failed} not done`);
process.exit(failed ? 1 : 0);
