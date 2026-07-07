const CACHE_NAME = 'nirman-manager-v3';
const APP_SHELL = [
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];

// ---- Firebase Cloud Messaging: lets a real push arrive even if the app/tab
// is fully closed, since the browser wakes this service worker up for it. ----
importScripts('https://www.gstatic.com/firebasejs/12.15.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.15.0/firebase-messaging-compat.js');
firebase.initializeApp({
  apiKey: "AIzaSyCP1yuIb2r6aKTq13evyMA6ZjTHLFaFJ10",
  authDomain: "nirman-manager-f9aa4.firebaseapp.com",
  projectId: "nirman-manager-f9aa4",
  storageBucket: "nirman-manager-f9aa4.firebasestorage.app",
  messagingSenderId: "882377352623",
  appId: "1:882377352623:web:288932793fb16a4627bb5a"
});
const fcmMessaging = firebase.messaging();
fcmMessaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || 'Nirman Manager';
  const body = (payload.notification && payload.notification.body) || '';
  self.registration.showNotification(title, {
    body,
    icon: './icon-192.png',
    badge: './icon-192.png',
    vibrate: [200, 100, 200]
  });
});

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      // Cache each file independently so one missing/renamed file doesn't
      // silently break precaching of all the others.
      return Promise.all(
        APP_SHELL.map((url) =>
          fetch(url).then((res) => {
            if (res && res.ok) return cache.put(url, res);
          }).catch(() => {})
        )
      );
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Serve from cache first, fall back to network (keeps app usable offline).
// IMPORTANT: only cache successful (200 OK) responses — never cache a 404/error,
// otherwise a broken response gets "stuck" and keeps showing forever.
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.match(event.request).then((cached) => {
      return fetch(event.request).then((res) => {
        if (res && res.ok) {
          const resClone = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, resClone)).catch(()=>{});
          return res;
        }
        // Network gave an error — prefer a good cached copy if we have one
        return cached || res;
      }).catch(() => cached);
    })
  );
});

// The page sends a message here whenever a reminder is due.
// Showing the notification through the Service Worker registration (instead of
// `new Notification()` on the page) means Android keeps it in the system tray
// properly and it also works while the app is a background tab / minimized.
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'SHOW_NOTIFICATION') {
    self.registration.showNotification(data.title || 'Nirman Manager', {
      body: data.body || '',
      icon: './icon-192.png',
      badge: './icon-192.png',
      tag: data.tag || undefined,
      renotify: !!data.tag,
      vibrate: [200, 100, 200]
    });
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (self.clients.openWindow) return self.clients.openWindow('./index.html');
    })
  );
});

// Best-effort: some Chromium browsers allow periodic background sync once the
// app is installed to the home screen. The browser decides the real interval
// (often several hours) — this is NOT a guarantee of exact-time reminders.
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'nirman-reminder-check') {
    event.waitUntil(
      self.clients.matchAll({ type: 'window' }).then((clientList) => {
        clientList.forEach((client) => client.postMessage({ type: 'CHECK_REMINDERS' }));
      })
    );
  }
});
