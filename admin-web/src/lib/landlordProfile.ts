import { doc, getDoc } from 'firebase/firestore'

import { db } from '../firebase'

/** Admin-only context: landlord row from `users/{landlordId}`. */
export interface LandlordVerification {
  uid: string
  email: string
  phone: string | null
  displayName: string
}

export async function fetchLandlordVerification(
  landlordId: string | undefined | null,
): Promise<LandlordVerification | null> {
  const trimmed = landlordId?.trim()
  if (!trimmed) return null
  const snap = await getDoc(doc(db, 'users', trimmed))
  if (!snap.exists()) return null
  const d = snap.data() as Record<string, unknown>
  const first = d.legalFirstName as string | undefined
  const last = d.legalLastName as string | undefined
  const name = [first, last].filter(Boolean).join(' ').trim()
  const email = (d.email as string) ?? ''
  const displayName = name || email || trimmed
  const rawPhone = d.phone
  const phone =
    rawPhone != null && String(rawPhone).trim() !== ''
      ? String(rawPhone).trim()
      : null
  return {
    uid: snap.id,
    email,
    phone,
    displayName,
  }
}
