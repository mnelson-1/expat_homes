import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useEditRequests } from '../context/EditRequestsContext'

export function EditRequestPendingDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { pending, approveRequest, rejectRequest } = useEditRequests()
  const [saving, setSaving] = useState(false)

  const request = pending.find((r) => r.id === id)

  if (!request) {
    return (
      <div className="page">
        <p>Request not found or already resolved.</p>
        <button type="button" className="btn btn-approve" onClick={() => navigate('/admin/edit-requests')}>
          Back to list
        </button>
      </div>
    )
  }

  const handleApproveRequest = async () => {
    setSaving(true)
    try {
      await approveRequest(request.id)
      navigate('/admin/edit-requests')
    } finally {
      setSaving(false)
    }
  }

  const handleReject = async () => {
    setSaving(true)
    try {
      await rejectRequest(request.id)
      navigate('/admin/edit-requests')
    } finally {
      setSaving(false)
    }
  }

  const proposed = request.proposedFields
  const listing = request.listing

  const fields = [
    { label: 'Title', current: listing.title, proposed: proposed.title },
    { label: 'Price', current: listing.price ?? '—', proposed: proposed.price },
    { label: 'Location', current: listing.address, proposed: proposed.location },
    { label: 'Description', current: listing.description ?? '—', proposed: proposed.description },
    { label: 'Type', current: '', proposed: proposed.type },
    { label: 'UPI', current: listing.upi ?? '—', proposed: proposed.upi },
  ]

  return (
    <div className="page" style={{ maxWidth: 900, margin: '0 auto' }}>
      <button
        type="button"
        className="btn"
        onClick={() => navigate('/admin/edit-requests')}
        style={{ marginBottom: 16 }}
      >
        &larr; Back
      </button>

      <h2 style={{ marginBottom: 4 }}>Edit Request Review</h2>
      <p style={{ color: '#666', marginBottom: 24 }}>
        Landlord: <strong>{listing.landlord || '—'}</strong> &middot; Requested: {request.requestedAt}
      </p>

      {listing.images?.length > 0 && (
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', marginBottom: 24 }}>
          {listing.images.map((url, i) => (
            <img
              key={i}
              src={url}
              alt={`listing-${i}`}
              style={{ width: 180, height: 120, objectFit: 'cover', borderRadius: 8 }}
            />
          ))}
        </div>
      )}

      <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: 24 }}>
        <thead>
          <tr style={{ background: '#f5f5f5' }}>
            <th style={thStyle}>Field</th>
            <th style={thStyle}>Current</th>
            <th style={thStyle}>Proposed Change</th>
          </tr>
        </thead>
        <tbody>
          {fields
            .filter((f) => f.proposed != null && f.proposed !== '')
            .map((f) => {
              const changed = f.proposed != null && f.proposed !== f.current
              return (
                <tr key={f.label}>
                  <td style={tdStyle}><strong>{f.label}</strong></td>
                  <td style={tdStyle}>{f.current}</td>
                  <td style={{ ...tdStyle, background: changed ? '#fff9c4' : undefined }}>
                    {f.proposed ?? '—'}
                  </td>
                </tr>
              )
            })}
        </tbody>
      </table>

      <div style={{ display: 'flex', gap: 12 }}>
        <button
          type="button"
          className="btn btn-reject"
          disabled={saving}
          onClick={handleReject}
        >
          Decline
        </button>
        <button
          type="button"
          className="btn btn-approve"
          disabled={saving}
          onClick={handleApproveRequest}
        >
          {saving ? 'Saving…' : 'Approve & Apply Changes'}
        </button>
      </div>
    </div>
  )
}

const thStyle: React.CSSProperties = {
  textAlign: 'left',
  padding: '10px 12px',
  borderBottom: '2px solid #ddd',
}

const tdStyle: React.CSSProperties = {
  padding: '10px 12px',
  borderBottom: '1px solid #eee',
  verticalAlign: 'top',
}
