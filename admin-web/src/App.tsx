import { Routes, Route, Navigate } from 'react-router-dom'
import { AdminLayout } from './layout/AdminLayout'
import { LoginPage } from './pages/LoginPage'
import { PendingListingsPage } from './pages/PendingListingsPage'
import { EditRequestsPage } from './pages/EditRequestsPage'

export default function App() {
  return (
    <Routes>
      <Route path="/admin/login" element={<LoginPage />} />
      <Route path="/admin" element={<AdminLayout />}>
        <Route index element={<Navigate to="/admin/listings/pending" replace />} />
        <Route path="listings/pending" element={<PendingListingsPage />} />
        <Route path="edit-requests" element={<EditRequestsPage />} />
      </Route>
      <Route path="/" element={<Navigate to="/admin/login" replace />} />
      <Route path="*" element={<Navigate to="/admin/login" replace />} />
    </Routes>
  )
}
