// Mock data for pending listings (until backend)
const MOCK_PENDING = [
  { id: '1', title: 'Charm Nest Apartments', address: 'Kiyovu, Kigali', landlord: 'Jean Claude', submittedAt: '2025-02-20' },
  { id: '2', title: 'Green View Villa', address: 'Nyarutarama, Kigali', landlord: 'Marie Uwera', submittedAt: '2025-02-19' },
]

export function PendingListingsPage() {
  return (
    <div className="page pending-listings-page">
      <h2 className="page-title">Pending listings</h2>
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
            {MOCK_PENDING.map((row) => (
              <tr key={row.id}>
                <td>{row.title}</td>
                <td>{row.address}</td>
                <td>{row.landlord}</td>
                <td>{row.submittedAt}</td>
                <td>
                  <button type="button" className="btn btn-approve">Approve</button>
                  <button type="button" className="btn btn-reject">Reject</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
