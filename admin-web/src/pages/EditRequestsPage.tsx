import { useNavigate } from 'react-router-dom'
import { useEditRequests } from '../context/EditRequestsContext'

export function EditRequestsPage() {
  const navigate = useNavigate()
  const { pending, loading } = useEditRequests()

  if (loading) {
    return (
      <div className="page edit-requests-page">
        <h2 className="page-title">Edit Requests</h2>
        <p className="placeholder-note">Loading…</p>
      </div>
    )
  }

  return (
    <div className="page edit-requests-page">
      <h2 className="page-title">Edit Requests</h2>
      <p className="page-description">Review landlord edit requests. Compare proposed changes and approve or decline.</p>

      <div className="table-wrap">
        {pending.length === 0 ? (
          <p className="placeholder-note">No pending edit requests.</p>
        ) : (
          <table className="admin-table">
            <thead>
              <tr>
                <th>Listing</th>
                <th>Address</th>
                <th>Landlord</th>
                <th>Requested</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {pending.map((row) => (
                <tr
                  key={row.id}
                  className="admin-table-row-clickable"
                  onClick={() => navigate(`/admin/edit-requests/pending/${row.id}`)}
                >
                  <td>{row.listing.title}</td>
                  <td>{row.listing.address}</td>
                  <td>{row.listing.landlord}</td>
                  <td>{row.requestedAt}</td>
                  <td onClick={(e) => e.stopPropagation()}>
                    <button
                      type="button"
                      className="btn btn-approve"
                      onClick={() => navigate(`/admin/edit-requests/pending/${row.id}`)}
                    >
                      Review
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
