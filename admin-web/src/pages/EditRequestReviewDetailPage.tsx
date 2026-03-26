import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useEditRequests, type EditRequestPending } from '../context/EditRequestsContext'
import type { Listing } from '../data/mockListings'
import {
  fetchLandlordVerification,
  type LandlordVerification,
} from '../lib/landlordProfile'

// Field labels for display in the comparison grid (keys match Firestore proposedFields).
const FIELD_KEYS = ['title', 'price', 'location', 'description', 'type', 'upi'] as const

const FIELD_LABELS: Record<(typeof FIELD_KEYS)[number], string> = {
  title: 'Title',
  price: 'Price',
  location: 'Address',
  description: 'Description',
  type: 'Type',
  upi: 'UPI',
}

function currentValueForProposedKey(listing: Listing, key: (typeof FIELD_KEYS)[number]): string | undefined {
  switch (key) {
    case 'location':
      return listing.address
    case 'title':
      return listing.title
    case 'price':
      return listing.price
    case 'description':
      return listing.description
    case 'upi':
      return listing.upi
    case 'type':
      return undefined
    default:
      return undefined
  }
}

function CompareRow({
  label,
  previous,
  updated,
}: {
  label: string
  previous: string | undefined
  updated: string | undefined
}) {
  const changed = (previous ?? '') !== (updated ?? '')
  return (
    <>
      <dt>{label}</dt>
      <dd style={changed ? { background: '#fff9c4' } : undefined}>
        {updated ?? '—'}
      </dd>
    </>
  )
}

function ReviewDetail({
  item,
  onAccept,
  onDecline,
  saving,
}: {
  item: EditRequestPending
  onAccept: () => void
  onDecline: () => void
  saving: boolean
}) {
  const proposed = item.proposedFields
  const prev = item.listing
  const [landlordVerification, setLandlordVerification] =
    useState<LandlordVerification | null>(null)

  useEffect(() => {
    if (!item.landlordId) {
      setLandlordVerification(null)
      return
    }
    let cancelled = false
    ;(async () => {
      try {
        const v = await fetchLandlordVerification(item.landlordId)
        if (!cancelled) setLandlordVerification(v)
      } catch {
        if (!cancelled) setLandlordVerification(null)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [item.id, item.landlordId])

  return (
    <div className="page listing-compare-page">
      <h2 className="page-title">Compare changes: {prev.title}</h2>
      <p className="page-description">
        Review proposed changes. Highlighted rows differ from the current listing.
        Accept to apply them; decline to reject without changes.
      </p>

      {landlordVerification && (
        <section
          className="detail-section"
          style={{
            maxWidth: 720,
            marginBottom: 24,
            padding: 16,
            background: '#f4f5f7',
            borderRadius: 12,
            border: '1px solid #e0e0e0',
          }}
        >
          <h3 className="detail-section-title" style={{ marginTop: 0 }}>
            Landlord account (admin)
          </h3>
          <dl className="detail-dl">
            <dt>Legal name</dt>
            <dd>{landlordVerification.displayName}</dd>
            <dt>Email</dt>
            <dd>{landlordVerification.email || '—'}</dd>
            <dt>Phone</dt>
            <dd>{landlordVerification.phone ?? '—'}</dd>
            <dt>User ID</dt>
            <dd>
              <code style={{ wordBreak: 'break-all' }}>{landlordVerification.uid}</code>
            </dd>
          </dl>
        </section>
      )}

      <div className="compare-grid">
        <section className="compare-column">
          <h3 className="detail-section-title">Current version</h3>
          {prev.images.length > 0 && (
            <div className="compare-images">
              {prev.images.map((src: string, i: number) => (
                <img key={i} src={src} alt={`Current ${i + 1}`} className="detail-image" />
              ))}
            </div>
          )}
          <dl className="detail-dl">
            <dt>Title</dt>
            <dd>{prev.title || '—'}</dd>
            <dt>Address</dt>
            <dd>{prev.address || '—'}</dd>
            <dt>Price</dt>
            <dd>{prev.price ?? '—'}</dd>
            <dt>UPI</dt>
            <dd>{prev.upi ?? '—'}</dd>
            <dt>Description</dt>
            <dd>{prev.description ?? '—'}</dd>
          </dl>
        </section>

        <section className="compare-column">
          <h3 className="detail-section-title">Proposed changes</h3>
          <p className="page-description" style={{ marginBottom: 8 }}>
            (Highlighted = changed from current)
          </p>
          <dl className="detail-dl">
            {FIELD_KEYS.map((key) => (
              <CompareRow
                key={key}
                label={FIELD_LABELS[key]}
                previous={currentValueForProposedKey(prev, key)}
                updated={proposed[key]}
              />
            ))}
          </dl>
        </section>
      </div>

      <div className="detail-actions">
        <button type="button" className="btn btn-reject" onClick={onDecline} disabled={saving}>
          Decline changes
        </button>
        <button type="button" className="btn btn-approve" onClick={onAccept} disabled={saving}>
          {saving ? 'Saving…' : 'Accept & apply changes'}
        </button>
      </div>
    </div>
  )
}

export function EditRequestReviewDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { pending, approveRequest, rejectRequest } = useEditRequests()
  const [saving, setSaving] = useState(false)

  const item = pending.find((r: EditRequestPending) => r.id === id)

  if (!item) {
    return (
      <div className="page">
        <p>Request not found or already resolved.</p>
        <button type="button" className="btn btn-approve" onClick={() => navigate('/admin/edit-requests')}>
          Back to list
        </button>
      </div>
    )
  }

  const handleAccept = async () => {
    setSaving(true)
    try {
      await approveRequest(item.id)
      navigate('/admin/edit-requests')
    } finally {
      setSaving(false)
    }
  }

  const handleDecline = async () => {
    setSaving(true)
    try {
      await rejectRequest(item.id)
      navigate('/admin/edit-requests')
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <button
        type="button"
        className="detail-back-btn"
        style={{ margin: '24px 0 0 24px' }}
        onClick={() => navigate('/admin/edit-requests')}
      >
        ← Back
      </button>
      <ReviewDetail
        item={item}
        onAccept={handleAccept}
        onDecline={handleDecline}
        saving={saving}
      />
    </>
  )
}
