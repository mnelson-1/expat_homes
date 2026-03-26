import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { doc, getDoc, serverTimestamp, updateDoc } from 'firebase/firestore'

import { ListingDetailView } from '../components/ListingDetailView'
import type { Listing } from '../data/mockListings'
import { auth, db } from '../firebase'
import {
  fetchLandlordVerification,
  type LandlordVerification,
} from '../lib/landlordProfile'

export function PendingListingDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [listing, setListing] = useState<Listing | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [landlordVerification, setLandlordVerification] =
    useState<LandlordVerification | null>(null)

  useEffect(() => {
    if (!id) return
    let cancelled = false
    ;(async () => {
      try {
        const snap = await getDoc(doc(db, 'listings', id))
        if (!snap.exists()) {
          if (!cancelled) {
            setError('Listing not found.')
            setLoading(false)
          }
          return
        }
        const data = snap.data() as any
        const landlordId = data.landlordId as string | undefined
        let verification: LandlordVerification | null = null
        if (landlordId) {
          try {
            verification = await fetchLandlordVerification(landlordId)
          } catch {
            verification = null
          }
        }
        const view: Listing = {
          id: snap.id,
          title: data.title ?? '',
          address: data.location ?? '',
          landlord: data.representativeName ?? data.landlordName ?? '',
          landlordPhone: data.landlordPhone as string | undefined,
          submittedAt: data.createdAt?.toDate?.().toLocaleDateString?.() ?? '',
          upi: data.upi as string | undefined,
          description: data.description as string | undefined,
          images: (data.mediaUrls as string[] | undefined) ?? [],
          price: data.price != null ? String(data.price) : undefined,
          bedrooms: data.bedrooms as number | undefined,
          bathrooms: data.bathrooms as number | undefined,
        }
        if (!cancelled) {
          setListing(view)
          setLandlordVerification(verification)
          setLoading(false)
        }
      } catch (err: any) {
        if (!cancelled) {
          setError(err.message ?? 'Failed to load listing.')
          setLoading(false)
        }
      }
    })()
    return () => {
      cancelled = true
    }
  }, [id])

  if (loading) {
    return (
      <div className="page">
        <p>Loading listing…</p>
      </div>
    )
  }

  if (!listing || error) {
    return (
      <div className="page">
        <p>{error ?? 'Listing not found.'}</p>
        <button type="button" className="btn btn-approve" onClick={() => navigate('/admin/listings/pending')}>
          Back to list
        </button>
      </div>
    )
  }

  const handleApprove = async () => {
    if (!id) return
    setSaving(true)
    try {
      const uid = auth.currentUser?.uid ?? null
      await updateDoc(doc(db, 'listings', id), {
        status: 'published',
        publishedAt: serverTimestamp(),
        verifiedBy: uid,
      })
      navigate('/admin/listings/pending')
    } catch (err) {
      // In a real app you might surface this in the UI.
      // For now, just navigate back.
      navigate('/admin/listings/pending')
    } finally {
      setSaving(false)
    }
  }

  const handleReject = async () => {
    if (!id) return
    setSaving(true)
    try {
      await updateDoc(doc(db, 'listings', id), {
        status: 'archived',
      })
      navigate('/admin/listings/pending')
    } catch (err) {
      navigate('/admin/listings/pending')
    } finally {
      setSaving(false)
    }
  }

  return (
    <ListingDetailView
      listing={listing}
      landlordVerification={landlordVerification}
      onBack={() => navigate('/admin/listings/pending')}
      secondaryAction={{ label: 'Reject', onClick: handleReject, className: 'btn-reject' }}
      primaryAction={{
        label: saving ? 'Saving…' : 'Approve',
        onClick: handleApprove,
        className: 'btn-approve',
      }}
    />
  )
}
