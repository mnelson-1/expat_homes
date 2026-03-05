import { useParams, useNavigate } from 'react-router-dom'
import { ListingDetailView } from '../components/ListingDetailView'
import { useEditRequests } from '../context/EditRequestsContext'

export function EditRequestPendingDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { pending, approveRequest, rejectRequest } = useEditRequests()
  const request = pending.find((r) => r.id === id)

  if (!request) {
    return (
      <div className="page">
        <p>Request not found.</p>
        <button type="button" className="btn btn-approve" onClick={() => navigate('/admin/edit-requests')}>
          Back to list
        </button>
      </div>
    )
  }

  const handleApproveRequest = () => {
    approveRequest(request.id)
    navigate('/admin/edit-requests')
  }

  const handleReject = () => {
    rejectRequest(request.id)
    navigate('/admin/edit-requests')
  }

  return (
    <ListingDetailView
      listing={request.listing}
      onBack={() => navigate('/admin/edit-requests')}
      secondaryAction={{ label: 'Reject', onClick: handleReject, className: 'btn-reject' }}
      primaryAction={{ label: 'Approve request', onClick: handleApproveRequest, className: 'btn-approve' }}
    />
  )
}
