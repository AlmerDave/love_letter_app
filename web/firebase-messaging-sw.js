// web/firebase-messaging-sw.js

// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase in service worker
firebase.initializeApp({
  apiKey: "AIzaSyCcOYAuXWHYqfzQe_Dpxitdsqdgn4SvPT8",
  authDomain: "love-letter-app-3c5b3.firebaseapp.com",
  databaseURL: "https://love-letter-app-3c5b3-default-rtdb.asia-southeast1.firebasedatabase.app/",
  projectId: "love-letter-app-3c5b3",
  storageBucket: "love-letter-app-3c5b3.firebasestorage.app",
  messagingSenderId: "1069598771619",
  appId: "1:1069598771619:web:a6b40cf8e150e731fbb216",
});

const messaging = firebase.messaging();

// // Handle background messages (when app is closed/minimized)
// messaging.onBackgroundMessage((payload) => {
//   console.log('🔔 Background message received:', payload);
  
//   const notificationTitle = payload.notification?.title || 'Love Letters 💕';
//   const notificationOptions = {
//     body: payload.notification?.body || 'You have a new love signal!',
//     icon: '/icons/Icon-192.png',
//     badge: '/icons/Icon-192.png',
//     tag: 'love-signal',
//     requireInteraction: false,
//     vibrate: [200, 100, 200], // Vibration pattern
//     data: {
//       url: '/', // URL to open when clicked
//       signalType: payload.data?.type || 'unknown',
//     },
//   };

//   // Show the notification
//   return self.registration.showNotification(notificationTitle, notificationOptions);
// });

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('👆 Notification clicked:', event);
  
  event.notification.close();
  
  // Open the app when notification is clicked
  event.waitUntil(
    clients.openWindow('/') // Opens your PWA
  );
});