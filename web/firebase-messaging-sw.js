importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyAeh8HZBZEBwFoCG9BYcJRuumLweTmTBaY",
  authDomain: "heytoliveapp.firebaseapp.com",
  projectId: "heytoliveapp",
  storageBucket: "heytoliveapp.appspot.com",
  messagingSenderId: "173456849188",
  appId: "1:173456849188:web:804c67b90a8d32d19d9bb1",
  measurementId: "G-6YDEYQSM18"
});
// Necessary to receive background messages:
const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
  console.log("onBackgroundMessage", m);
});