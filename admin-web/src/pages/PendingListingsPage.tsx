import { useNavigate } from 'react-router-dom'
import { MOCK_PENDING_LISTINGS } from '../data/mockListings'

export function PendingListingsPage() {
  const navigate = useNavigate()

  return (
    <div className="page pending-listings-page">
      <h2 className="page-title">Pending Verification</h2>
      <p className="page-description">Review and verify listings before they go live.</p>
      <div className="table-wrap">
        <table className="admin-table">
          <thead>
            <tr>
              <th>Listing</th>
              <th>Address</th>
              <th>Landlord</th>
              <th>Submitted</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {MOCK_PENDING_LISTINGS.map((row) => (
              <tr
                key={row.id}
                className="admin-table-row-clickable"
                onClick={() => navigate(`/admin/listings/pending/${row.id}`)}
              >
                <td>{row.title}</td>
                <td>{row.address}</td>
                <td>{row.landlord}</td>
                <td>{row.submittedAt}</td>
                <td onClick={(e) => e.stopPropagation()}>
                  <button
                    type="button"
                    className="btn btn-approve"
                    onClick={() => navigate(`/admin/listings/pending/${row.id}`)}
                  >
                    View
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
