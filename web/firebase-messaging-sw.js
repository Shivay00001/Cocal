// Firebase Cloud Messaging Service Worker
// This file is required for push notifications to work

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: "AIzaSyBQsxXk98-T47biTA5zgGbI0yOQK6eq2Co",
  authDomain: "cocal-visionquantech.firebaseapp.com",
  projectId: "cocal-visionquantech",
  storageBucket: "cocal-visionquantech.firebasestorage.app",
  messagingSenderId: "768213217292",
  appId: "1:768213217292:web:c57a7a93bcd76a5017fe29"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'CoCal Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
