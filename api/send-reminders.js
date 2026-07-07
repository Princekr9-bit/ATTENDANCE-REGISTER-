// This runs on Vercel's server (not in the browser). Every minute, an external
// cron service (cron-job.org) calls this URL. It checks Firestore for reminders
// that are due right now and sends a real push notification to the phone(s)
// that have this app installed — this works even if the app/tab is fully closed.

const admin = require('firebase-admin');

function getApp() {
  if (admin.apps.length) return admin.app();
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n');
  return admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey
    })
  });
}

module.exports = async (req, res) => {
  // Simple shared-secret check so random people on the internet can't trigger this.
  const secret = req.query.secret || (req.headers['x-cron-secret']);
  if (!process.env.CRON_SECRET || secret !== process.env.CRON_SECRET) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    getApp();
    const db = admin.firestore();
    const messaging = admin.messaging();
    const nowIso = new Date().toISOString();

    const dueSnap = await db.collection('scheduledNotifications')
      .where('sent', '==', false)
      .where('sendAt', '<=', nowIso)
      .get();

    if (dueSnap.empty) {
      res.status(200).json({ ok: true, sent: 0 });
      return;
    }

    const tokensSnap = await db.collection('pushTokens').get();
    const tokens = tokensSnap.docs.map((d) => d.data().token).filter(Boolean);

    let sentCount = 0;
    const errors = [];

    for (const doc of dueSnap.docs) {
      const data = doc.data();
      if (tokens.length) {
        const message = {
          notification: {
            title: data.title || 'Nirman Manager',
            body: data.body || ''
          },
          tokens
        };
        try {
          const result = await messaging.sendEachForMulticast(message);
          sentCount += result.successCount;
          result.responses.forEach((r, i) => {
            if (!r.success) errors.push({ token: tokens[i], error: r.error && r.error.message });
          });
        } catch (e) {
          errors.push({ error: e.message });
        }
      }
      await doc.ref.update({ sent: true, sentAt: nowIso });
    }

    res.status(200).json({ ok: true, checked: dueSnap.size, sent: sentCount, errors });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};
