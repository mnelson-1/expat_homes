import { useParams, useNavigate } from 'react-router-dom'
import { useEditRequests } from '../context/EditRequestsContext'

export function EditRequestReviewDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { review, acceptChanges, declineChanges } = useEditRequests()
  const item = review.find((r) => r.id === id)

  if (!item) {
    return (
      <div className="page">
        <p>Request not found.</p>
        <button type="button" className="btn btn-approve" onClick={() => navigate('/admin/edit-requests')}>
          Back to list
        </button>
      </div>
    )
  }

  const handleAccept = () => {
    acceptChanges(item.id)
    navigate('/admin/edit-requests')
  }

  const handleDecline = () => {
    declineChanges(item.id)
    navigate('/admin/edit-requests')
  }

  return (
    <div className="page listing-compare-page">
      <button type="button" className="detail-back-btn" onClick={() => navigate('/admin/edit-requests')}>
        ← Back
      </button>
      <h2 className="page-title">Compare changes: {item.previous.title}</h2>
      <p className="page-description">Review previous vs updated listing and accept or decline the changes.</p>

      <div className="compare-grid">
        <section className="compare-column">
          <h3 className="detail-section-title">Previous version</h3>
          <div className="compare-images">
            {item.previous.images.map((src, i) => (
              <img key={i} src={src} alt={`Previous ${i + 1}`} className="detail-image" />
            ))}
          </div>
          <dl className="detail-dl">
            <dt>UPI</dt>
            <dd>{item.previous.upi ?? '—'}</dd>
            <dt>Price</dt>
            <dd>{item.previous.price ?? '—'}</dd>
            <dt>Bedrooms / Bathrooms</dt>
            <dd>{item.previous.bedrooms ?? '—'} / {item.previous.bathrooms ?? '—'}</dd>
            <dt>Description</dt>
            <dd>{item.previous.description ?? '—'}</dd>
          </dl>
        </section>
        <section className="compare-column">
          <h3 className="detail-section-title">New version</h3>
          <div className="compare-images">
            {item.updated.images.map((src, i) => (
              <img key={i} src={src} alt={`Updated ${i + 1}`} className="detail-image" />
            ))}
          </div>
          <dl className="detail-dl">
            <dt>UPI</dt>
            <dd>{item.updated.upi ?? '—'}</dd>
            <dt>Price</dt>
            <dd>{item.updated.price ?? '—'}</dd>
            <dt>Bedrooms / Bathrooms</dt>
            <dd>{item.updated.bedrooms ?? '—'} / {item.updated.bathrooms ?? '—'}</dd>
            <dt>Description</dt>
            <dd>{item.updated.description ?? '—'}</dd>
          </dl>
        </section>
      </div>

      <div className="detail-actions">
        <button type="button" className="btn btn-reject" onClick={handleDecline}>
          Decline changes
        </button>
        <button type="button" className="btn btn-approve" onClick={handleAccept}>
          Accept changes
        </button>
      </div>
    </div>
  )
}
