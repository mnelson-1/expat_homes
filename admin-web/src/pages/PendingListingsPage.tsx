import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { collection, onSnapshot, orderBy, query, where } from 'firebase/firestore'

import type { Listing } from '../data/mockListings'
import { db } from '../firebase'

export function PendingListingsPage() {
  const navigate = useNavigate()
  const [rows, setRows] = useState<Listing[]>([])

  useEffect(() => {
    const q = query(
      collection(db, 'listings'),
      where('status', '==', 'pending_verification'),
      orderBy('createdAt', 'desc'),
    )

    const unsub = onSnapshot(q, (snap) => {
      const next: Listing[] = snap.docs.map((doc) => {
        const data = doc.data() as any
        return {
          id: doc.id,
          title: data.title ?? '',
          address: data.location ?? '',
          landlord: data.representativeName ?? data.landlordName ?? '',
          landlordPhone: data.landlordPhone as string | undefined,
          submittedAt: data.createdAt?.toDate?.().toLocaleDateString?.() ?? '',
          upi: data.upi as string | undefined,
          description: data.description as string | undefined,
          images: (data.mediaUrls as string[] | undefined) ?? [],
          price: data.price != null ? String(data.price) : undefined,
          bedrooms: data.bedrooms as number | undefined,
          bathrooms: data.bathrooms as number | undefined,
        }
      })
      setRows(next)
    })

    return () => unsub()
  }, [])

  return (
    <div className="page pending-listings-page">
      <h2 className="page-title">Pending Verification</h2>
      <p className="page-description">Review and verify listings before they go live.</p>
      <div className="table-wrap">
        {rows.length === 0 ? (
          <p className="placeholder-note">No listings awaiting verification.</p>
        ) : (
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
              {rows.map((row) => (
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
        )}
      </div>
    </div>
  )
}
