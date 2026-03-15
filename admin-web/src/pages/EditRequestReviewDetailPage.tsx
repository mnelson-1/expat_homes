import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useEditRequests, type EditRequestReview } from '../context/EditRequestsContext'

// Field labels for display in the comparison grid.
const FIELD_LABELS: Record<string, string> = {
  title: 'Title',
  price: 'Price',
  location: 'Address',
  description: 'Description',
  type: 'Type',
  upi: 'UPI',
}

function CompareRow({ label, previous, updated }: {
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

function ReviewDetail({ item, onAccept, onDecline, saving }: {
  item: EditRequestReview
  onAccept: () => void
  onDecline: () => void
  saving: boolean
}) {
  const proposed = item.proposedFields
  const prev = item.previous

  return (
    <div className="page listing-compare-page">
      <h2 className="page-title">Compare changes: {prev.title}</h2>
      <p className="page-description">
        Review proposed changes. Highlighted rows differ from the current listing.
        Accept to apply them; decline to reject without changes.
      </p>

      <div className="compare-grid">
        <section className="compare-column">
          <h3 className="detail-section-title">Current version</h3>
          {prev.images.length > 0 && (
            <div className="compare-images">
              {prev.images.map((src, i) => (
                <img key={i} src={src} alt={`Current ${i + 1}`} className="detail-image" />
              ))}
            </div>
          )}
          <dl className="detail-dl">
            <dt>Title</dt><dd>{prev.title || '—'}</dd>
            <dt>Address</dt><dd>{prev.address || '—'}</dd>
            <dt>Price</dt><dd>{prev.price ?? '—'}</dd>
            <dt>UPI</dt><dd>{prev.upi ?? '—'}</dd>
            <dt>Description</dt><dd>{prev.description ?? '—'}</dd>
          </dl>
        </section>

        <section className="compare-column">
          <h3 className="detail-section-title">Proposed changes</h3>
          <p className="page-description" style={{ marginBottom: 8 }}>
            (Highlighted = changed from current)
          </p>
          <dl className="detail-dl">
            {Object.keys(FIELD_LABELS).map((key) => (
              <CompareRow
                key={key}
                label={FIELD_LABELS[key]}
                previous={(prev as any)[key === 'address' ? 'address' : key] as string | undefined}
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
  const { review, acceptChanges, declineChanges } = useEditRequests()
  const [saving, setSaving] = useState(false)

  const item = review.find((r) => r.id === id)

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
      await acceptChanges(item.id)
      navigate('/admin/edit-requests')
    } finally {
      setSaving(false)
    }
  }

  const handleDecline = async () => {
    setSaving(true)
    try {
      await declineChanges(item.id)
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
