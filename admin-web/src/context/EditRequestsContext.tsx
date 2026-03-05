import { createContext, useContext, useState, useCallback, type ReactNode } from 'react'
import {
  MOCK_EDIT_PENDING,
  MOCK_EDIT_REVIEW,
  type EditRequestPending,
  type EditRequestReview,
} from '../data/mockListings'

interface EditRequestsState {
  pending: EditRequestPending[]
  review: EditRequestReview[]
  approveRequest: (id: string) => void
  rejectRequest: (id: string) => void
  acceptChanges: (id: string) => void
  declineChanges: (id: string) => void
}

const EditRequestsContext = createContext<EditRequestsState | null>(null)

export function EditRequestsProvider({ children }: { children: ReactNode }) {
  const [pending, setPending] = useState<EditRequestPending[]>(MOCK_EDIT_PENDING)
  const [review, setReview] = useState<EditRequestReview[]>(MOCK_EDIT_REVIEW)

  const approveRequest = useCallback((id: string) => {
    setPending((prev) => {
      const item = prev.find((r) => r.id === id)
      if (!item) return prev
      setReview((r) => [
        ...r,
        {
          id: item.id,
          listingId: item.listingId,
          previous: item.listing,
          updated: { ...item.listing, submittedAt: new Date().toISOString().slice(0, 10) },
          submittedAt: new Date().toISOString().slice(0, 10),
        },
      ])
      return prev.filter((r) => r.id !== id)
    })
  }, [])

  const rejectRequest = useCallback((id: string) => {
    setPending((prev) => prev.filter((r) => r.id !== id))
  }, [])

  const acceptChanges = useCallback((id: string) => {
    setReview((prev) => prev.filter((r) => r.id !== id))
  }, [])

  const declineChanges = useCallback((id: string) => {
    setReview((prev) => prev.filter((r) => r.id !== id))
  }, [])

  const value: EditRequestsState = {
    pending,
    review,
    approveRequest,
    rejectRequest,
    acceptChanges,
    declineChanges,
  }

  return (
    <EditRequestsContext.Provider value={value}>
      {children}
    </EditRequestsContext.Provider>
  )
}

export function useEditRequests() {
  const ctx = useContext(EditRequestsContext)
  if (!ctx) throw new Error('useEditRequests must be used within EditRequestsProvider')
  return ctx
}
