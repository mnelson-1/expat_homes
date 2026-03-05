import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useEditRequests } from '../context/EditRequestsContext'

export function EditRequestsPage() {
  const navigate = useNavigate()
  const { pending, review } = useEditRequests()
  const [activeTab, setActiveTab] = useState<'pending' | 'review'>('pending')

  return (
    <div className="page edit-requests-page">
      <h2 className="page-title">Edit Requests</h2>
      <p className="page-description">Approve or reject landlord edit requests. Approve a request to allow edits; then review the changes in Ready for review.</p>

      <div className="edit-requests-tabs">
        <button
          type="button"
          className={`edit-requests-tab ${activeTab === 'pending' ? 'active' : ''}`}
          onClick={() => setActiveTab('pending')}
        >
          Pending requests
        </button>
        <button
          type="button"
          className={`edit-requests-tab ${activeTab === 'review' ? 'active' : ''}`}
          onClick={() => setActiveTab('review')}
        >
          Ready for review
        </button>
      </div>

      {activeTab === 'pending' && (
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
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {activeTab === 'review' && (
        <div className="table-wrap">
          {review.length === 0 ? (
            <p className="placeholder-note">No requests ready for review. Approve a pending request to move it here.</p>
          ) : (
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Listing</th>
                  <th>Address</th>
                  <th>Changes submitted</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {review.map((row) => (
                  <tr
                    key={row.id}
                    className="admin-table-row-clickable"
                    onClick={() => navigate(`/admin/edit-requests/review/${row.id}`)}
                  >
                    <td>{row.previous.title}</td>
                    <td>{row.previous.address}</td>
                    <td>{row.submittedAt}</td>
                    <td onClick={(e) => e.stopPropagation()}>
                      <button
                        type="button"
                        className="btn btn-approve"
                        onClick={() => navigate(`/admin/edit-requests/review/${row.id}`)}
                      >
                        Compare
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}
