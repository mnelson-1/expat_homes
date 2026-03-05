import { Routes, Route, Navigate } from 'react-router-dom'
import { AdminLayout } from './layout/AdminLayout'
import { LoginPage } from './pages/LoginPage'
import { PendingListingsPage } from './pages/PendingListingsPage'
import { PendingListingDetailPage } from './pages/PendingListingDetailPage'
import { EditRequestsPage } from './pages/EditRequestsPage'
import { EditRequestPendingDetailPage } from './pages/EditRequestPendingDetailPage'
import { EditRequestReviewDetailPage } from './pages/EditRequestReviewDetailPage'

export default function App() {
  return (
    <Routes>
      <Route path="/admin/login" element={<LoginPage />} />
      <Route path="/admin" element={<AdminLayout />}>
        <Route index element={<Navigate to="/admin/listings/pending" replace />} />
        <Route path="listings/pending" element={<PendingListingsPage />} />
        <Route path="listings/pending/:id" element={<PendingListingDetailPage />} />
        <Route path="edit-requests" element={<EditRequestsPage />} />
        <Route path="edit-requests/pending/:id" element={<EditRequestPendingDetailPage />} />
        <Route path="edit-requests/review/:id" element={<EditRequestReviewDetailPage />} />
      </Route>
      <Route path="/" element={<Navigate to="/admin/login" replace />} />
      <Route path="*" element={<Navigate to="/admin/login" replace />} />
    </Routes>
  )
}
