import { initializeApp, type FirebaseOptions } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

// Firebase configuration for the admin web dashboard.
// Values are provided via Vite env vars (see docs/FIREBASE_SETUP.md and admin-web/.env.example).
function readFirebaseOptions(): FirebaseOptions {
  const apiKey = import.meta.env.VITE_FIREBASE_API_KEY
  if (!apiKey?.trim()) {
    throw new Error(
      'Missing VITE_FIREBASE_API_KEY. Create admin-web/.env.local from .env.example ' +
        'and add your Firebase Web config (see docs/FIREBASE_SETUP.md §9.2). Then restart `npm run dev`.',
    )
  }

  const opts: FirebaseOptions = {
    apiKey: apiKey.trim(),
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  }

  const appId = import.meta.env.VITE_FIREBASE_APP_ID?.trim()
  if (appId) {
    opts.appId = appId
  }

  return opts
}

const app = initializeApp(readFirebaseOptions())

export const auth = getAuth(app)
export const db = getFirestore(app)

