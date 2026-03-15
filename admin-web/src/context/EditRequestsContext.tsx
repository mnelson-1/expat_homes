import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react'
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore'

import { auth, db } from '../firebase'
import type { Listing } from '../data/mockListings'

// ---------------------------------------------------------------------------
// Shared types
// ---------------------------------------------------------------------------

export interface EditRequestPending {
  id: string
  listingId: string
  landlordId: string
  listing: Listing
  proposedFields: Record<string, string>
  requestedAt: string
  reason?: string
}

interface EditRequestsState {
  pending: EditRequestPending[]
  loading: boolean
  approveRequest: (id: string) => Promise<void>
  rejectRequest: (id: string) => Promise<void>
}

// ---------------------------------------------------------------------------
// Context
// ---------------------------------------------------------------------------

const EditRequestsContext = createContext<EditRequestsState | null>(null)

// ---------------------------------------------------------------------------
// Provider — subscribes to Firestore `edit_requests` (status == 'pending')
// ---------------------------------------------------------------------------

export function EditRequestsProvider({ children }: { children: ReactNode }) {
  const [pending, setPending] = useState<EditRequestPending[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const reqQ = query(
      collection(db, 'edit_requests'),
      where('status', '==', 'pending'),
      orderBy('createdAt', 'desc'),
    )

    const unsubReq = onSnapshot(reqQ, async (reqSnap) => {
      if (reqSnap.empty) {
        setPending([])
        setLoading(false)
        return
      }

      const items: EditRequestPending[] = await Promise.all(
        reqSnap.docs.map(async (reqDoc) => {
          const reqData = reqDoc.data() as any
          let listing: Listing = {
            id: reqData.listingId ?? '',
            title: '…',
            address: '',
            landlord: '',
            submittedAt: '',
            images: [],
          }
          try {
            const { getDoc, doc: firestoreDoc } = await import('firebase/firestore')
            const lstSnap = await getDoc(firestoreDoc(db, 'listings', reqData.listingId))
            if (lstSnap.exists()) {
              const d = lstSnap.data() as any
              listing = {
                id: lstSnap.id,
                title: d.title ?? '',
                address: d.location ?? '',
                landlord: d.representativeName ?? '',
                landlordPhone: d.landlordPhone,
                submittedAt: d.createdAt?.toDate?.().toLocaleDateString?.() ?? '',
                upi: d.upi,
                description: d.description,
                images: (d.mediaUrls as string[] | undefined) ?? [],
                price: d.price != null ? String(d.price) : undefined,
              }
            }
          } catch (_) {}
          return {
            id: reqDoc.id,
            listingId: reqData.listingId ?? '',
            landlordId: reqData.landlordId ?? '',
            listing,
            proposedFields: reqData.proposedFields ?? {},
            requestedAt: reqData.createdAt?.toDate?.().toLocaleDateString?.() ?? '',
            reason: reqData.reason,
          }
        }),
      )
      setPending(items)
      setLoading(false)
    })

    return () => {
      unsubReq()
    }
  }, [])

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  const approveRequest = async (id: string) => {
    const uid = auth.currentUser?.uid ?? null
    const item = pending.find((p) => p.id === id)
    if (!item) return

    const batch = writeBatch(db)

    // Apply proposed field changes to the listing.
    const proposed = item.proposedFields
    const listingUpdate: Record<string, any> = { updatedAt: serverTimestamp() }
    if (proposed.title) listingUpdate.title = proposed.title
    if (proposed.price) listingUpdate.price = proposed.price
    if (proposed.location) listingUpdate.location = proposed.location
    if (proposed.description) listingUpdate.description = proposed.description
    if (proposed.type) listingUpdate.type = proposed.type
    if (proposed.upi) listingUpdate.upi = proposed.upi

    batch.update(doc(db, 'listings', item.listingId), listingUpdate)

    // Mark the edit request as approved.
    batch.update(doc(db, 'edit_requests', id), {
      status: 'approved',
      reviewedBy: uid,
      reviewedAt: serverTimestamp(),
    })

    await batch.commit()
  }

  const rejectRequest = async (id: string) => {
    const uid = auth.currentUser?.uid ?? null
    await updateDoc(doc(db, 'edit_requests', id), {
      status: 'declined',
      reviewedBy: uid,
      reviewedAt: serverTimestamp(),
    })
  }

  return (
    <EditRequestsContext.Provider
      value={{ pending, loading, approveRequest, rejectRequest }}
    >
      {children}
    </EditRequestsContext.Provider>
  )
}

export function useEditRequests() {
  const ctx = useContext(EditRequestsContext)
  if (!ctx) throw new Error('useEditRequests must be used within EditRequestsProvider')
  return ctx
}
