import type { Listing } from '../data/mockListings'
import type { LandlordVerification } from '../lib/landlordProfile'

interface ListingDetailViewProps {
  listing: Listing
  onBack: () => void
  primaryAction?: { label: string; onClick: () => void; className: string }
  secondaryAction?: { label: string; onClick: () => void; className: string }
  /** From Firestore `users/{landlordId}` when super admin reviews a listing */
  landlordVerification?: LandlordVerification | null
}

export function ListingDetailView({
  listing,
  onBack,
  primaryAction,
  secondaryAction,
  landlordVerification,
}: ListingDetailViewProps) {
  return (
    <div className="page listing-detail-page">
      <button type="button" className="detail-back-btn" onClick={onBack}>
        ← Back
      </button>
      <h2 className="page-title">{listing.title}</h2>
      <p className="page-description">{listing.address}</p>

      {listing.images && listing.images.length > 0 && (
        <section className="detail-section">
          <h3 className="detail-section-title">Photos</h3>
          <div className="detail-images">
            {listing.images.map((src, i) => (
              <img key={i} src={src} alt={`${listing.title} ${i + 1}`} className="detail-image" />
            ))}
          </div>
        </section>
      )}

      <section className="detail-section">
        <h3 className="detail-section-title">Details</h3>
        <dl className="detail-dl">
          {listing.upi && (
            <>
              <dt>UPI</dt>
              <dd>{listing.upi}</dd>
            </>
          )}
          <dt>Landlord</dt>
          <dd>{listing.landlord}</dd>
          {listing.landlordPhone && (
            <>
              <dt>Phone</dt>
              <dd>{listing.landlordPhone}</dd>
            </>
          )}
          <dt>Submitted</dt>
          <dd>{listing.submittedAt}</dd>
          {listing.price && (
            <>
              <dt>Price</dt>
              <dd>{listing.price}</dd>
            </>
          )}
          {listing.bedrooms != null && (
            <>
              <dt>Bedrooms</dt>
              <dd>{listing.bedrooms}</dd>
            </>
          )}
          {listing.bathrooms != null && (
            <>
              <dt>Bathrooms</dt>
              <dd>{listing.bathrooms}</dd>
            </>
          )}
        </dl>
      </section>

      {landlordVerification && (
        <section className="detail-section landlord-verification">
          <h3 className="detail-section-title">Landlord account (admin)</h3>
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

      {listing.description && (
        <section className="detail-section">
          <h3 className="detail-section-title">Description</h3>
          <p className="detail-description">{listing.description}</p>
        </section>
      )}

      <div className="detail-actions">
        {secondaryAction && (
          <button
            type="button"
            className={`btn ${secondaryAction.className}`}
            onClick={secondaryAction.onClick}
          >
            {secondaryAction.label}
          </button>
        )}
        {primaryAction && (
          <button
            type="button"
            className={`btn ${primaryAction.className}`}
            onClick={primaryAction.onClick}
          >
            {primaryAction.label}
          </button>
        )}
      </div>
    </div>
  )
}
