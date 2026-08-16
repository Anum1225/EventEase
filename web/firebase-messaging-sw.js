// Firebase Messaging Service Worker for Web Push Notifications
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDzJyRmAOpDMkkeQT9yECkxQfF8WY8wpwU",
  authDomain: "eventease-acd2b.firebaseapp.com",
  projectId: "eventease-acd2b",
  storageBucket: "eventease-acd2b.firebasestorage.app",
  messagingSenderId: "1086036070034",
  appId: "1:1086036070034:web:0b73c4ee40538a06141a02"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message: ', payload);
  const notificationTitle = payload.notification?.title || 'Event notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
