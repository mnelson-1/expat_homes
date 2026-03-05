import { useParams, useNavigate } from 'react-router-dom'
import { ListingDetailView } from '../components/ListingDetailView'
import { MOCK_PENDING_LISTINGS } from '../data/mockListings'

export function PendingListingDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const listing = MOCK_PENDING_LISTINGS.find((l) => l.id === id)

  if (!listing) {
    return (
      <div className="page">
        <p>Listing not found.</p>
        <button type="button" className="btn btn-approve" onClick={() => navigate('/admin/listings/pending')}>
          Back to list
        </button>
      </div>
    )
  }

  const handleApprove = () => {
    // TODO: API call
    navigate('/admin/listings/pending')
  }

  const handleReject = () => {
    // TODO: API call
    navigate('/admin/listings/pending')
  }

  return (
    <ListingDetailView
      listing={listing}
      onBack={() => navigate('/admin/listings/pending')}
      secondaryAction={{ label: 'Reject', onClick: handleReject, className: 'btn-reject' }}
      primaryAction={{ label: 'Approve', onClick: handleApprove, className: 'btn-approve' }}
    />
  )
}
