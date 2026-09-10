// This runs on Vercel's server (not in the browser). Every minute, an external
// cron service (cron-job.org) calls this URL. It checks Firestore for reminders
// that are due right now and sends a real push notification to the phone(s)
// that have this app installed — this works even if the app/tab is fully closed.

const admin = require('firebase-admin');

const MAX_TOKENS_PER_BATCH = 500; // FCM's hard limit per multicast call
const CLAIM_LOCK_MS = 2 * 60 * 1000; // if a claim is older than this, treat it as abandoned and retry
const MAX_ATTEMPTS = 30; // give up retrying a single notification after this many tries

function getApp() {
  if (admin.apps.length) return admin.app();
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const svc = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    return admin.initializeApp({ credential: admin.credential.cert(svc) });
  }
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n');
  return admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey
    })
  });
}

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function cleanupInvalidTokens(db, tokenDocIds) {
  if (!tokenDocIds.length) return;
  try {
    const batch = db.batch();
    tokenDocIds.forEach((id) => batch.delete(db.collection('pushTokens').doc(id)));
    await batch.commit();
  } catch (e) {
    console.error('Token cleanup failed (will retry naturally later):', e.message);
  }
}

module.exports = async (req, res) => {
  // Header-only secret now — a query string (?secret=...) can leak into
  // logs/history/monitoring. Configure your cron service to send:
  // x-cron-secret: <CRON_SECRET>
  const secret = req.headers['x-cron-secret'];
  if (!process.env.CRON_SECRET || secret !== process.env.CRON_SECRET) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    getApp();
    const db = admin.firestore();
    const messaging = admin.messaging();
    const now = admin.firestore.Timestamp.now();

    // sendAt is stored as a Firestore Timestamp by the app, so it must be
    // queried as a Timestamp too (comparing it to an ISO string never
    // matched anything and reminders were silently never sent).
    const dueSnap = await db.collection('scheduledNotifications')
      .where('sent', '==', false)
      .where('sendAt', '<=', now)
      .get();

    if (dueSnap.empty) {
      res.status(200).json({ ok: true, checked: 0, sent: 0 });
      return;
    }

    const tokensSnap = await db.collection('pushTokens').get();
    const tokenEntries = tokensSnap.docs
      .map((d) => ({ id: d.id, token: d.data().token }))
      .filter((e) => e.token);
    const invalidTokenDocIds = new Set();

    let sentCount = 0;
    let skippedClaimed = 0;
    let permanentlyFailed = 0;
    const errors = [];

    for (const doc of dueSnap.docs) {
      // Atomic claim-lock so two overlapping cron runs can't both process
      // (and double-send) the same notification.
      let claimed = false;
      try {
        await db.runTransaction(async (tx) => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return;
          const d = fresh.data();
          if (d.sent) return;
          const claimedAt = d.claimedAt ? d.claimedAt.toMillis() : 0;
          const stillLocked = claimedAt && (Date.now() - claimedAt) < CLAIM_LOCK_MS;
          if (stillLocked) return;
          tx.update(doc.ref, {
            claimedAt: admin.firestore.FieldValue.serverTimestamp(),
            attempts: admin.firestore.FieldValue.increment(1)
          });
          claimed = true;
        });
      } catch (e) {
        errors.push({ id: doc.id, error: 'claim-failed: ' + e.message });
        continue;
      }
      if (!claimed) { skippedClaimed++; continue; }

      const data = doc.data();
      const attempts = (data.attempts || 0) + 1;

      if (!tokenEntries.length) {
        // No devices registered yet is NOT the same as "delivered" — keep
        // sent=false so a future run (once a token exists) retries.
        await doc.ref.update({
          sent: false,
          lastError: 'no push tokens registered',
          lastAttemptAt: admin.firestore.FieldValue.serverTimestamp()
        });
        continue;
      }

      let successCount = 0;
      const notifErrors = [];
      for (const batch of chunk(tokenEntries, MAX_TOKENS_PER_BATCH)) {
        const message = {
          notification: { title: data.title || 'Nirman Manager', body: data.body || '' },
          tokens: batch.map((e) => e.token)
        };
        try {
          const result = await messaging.sendEachForMulticast(message);
          successCount += result.successCount;
          result.responses.forEach((r, i) => {
            if (r.success) return;
            const code = r.error && r.error.code;
            notifErrors.push({ token: batch[i].token, error: r.error && r.error.message });
            if (code === 'messaging/registration-token-not-registered' ||
                code === 'messaging/invalid-registration-token' ||
                code === 'messaging/invalid-argument') {
              invalidTokenDocIds.add(batch[i].id);
            }
          });
        } catch (e) {
          notifErrors.push({ error: e.message });
        }
      }

      if (successCount > 0) {
        await doc.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          successCount
        });
        sentCount += successCount;
      } else {
        const giveUp = attempts >= MAX_ATTEMPTS;
        await doc.ref.update({
          sent: giveUp ? true : false,
          failedPermanently: !!giveUp,
          lastError: (notifErrors[0] && notifErrors[0].error) || 'unknown send failure',
          lastAttemptAt: admin.firestore.FieldValue.serverTimestamp()
        });
        if (giveUp) permanentlyFailed++;
        errors.push({ id: doc.id, errors: notifErrors });
      }
    }

    await cleanupInvalidTokens(db, Array.from(invalidTokenDocIds));

    res.status(200).json({
      ok: true,
      checked: dueSnap.size,
      sent: sentCount,
      skippedClaimed,
      permanentlyFailed,
      tokensCleanedUp: invalidTokenDocIds.size,
      errors
    });
  } catch (e) {
    console.error('send-reminders failed:', e);
    res.status(500).json({ error: 'internal_error' });
  }
};
