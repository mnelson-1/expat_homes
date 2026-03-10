import { useEffect, useState } from 'react'
import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { onAuthStateChanged, signOut } from 'firebase/auth'

import { auth } from '../firebase'
import { EditRequestsProvider } from '../context/EditRequestsContext'
import pendingIcon from '../../images/Pending Verification Icon.png'
import editIcon from '../../images/Edit Request Icon.png'
import logoutIcon from '../../images/Logout Icon.png'

export function AdminLayout() {
  const navigate = useNavigate()
  const [checkingAuth, setCheckingAuth] = useState(true)

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (user) => {
      if (!user) {
        navigate('/admin/login', { replace: true })
      }
      setCheckingAuth(false)
    })
    return () => unsub()
  }, [navigate])

  const handleLogout = async () => {
    await signOut(auth)
    navigate('/admin/login', { replace: true })
  }

  if (checkingAuth) {
    return (
      <div className="admin-layout">
        <main className="admin-main">
          <p>Checking admin session…</p>
        </main>
      </div>
    )
  }

  return (
    <div className="admin-layout">
      <aside className="admin-sidebar">
        <div className="admin-sidebar-brand">expat-admin</div>
        <nav className="admin-nav">
          <NavLink
            to="/admin/listings/pending"
            className={({ isActive }) => (isActive ? 'admin-nav-link active' : 'admin-nav-link')}
          >
            <img src={pendingIcon} alt="" className="admin-nav-icon" />
            Pending Verification
          </NavLink>
          <hr className="admin-nav-divider" />
          <NavLink
            to="/admin/edit-requests"
            end={false}
            className={({ isActive }) => (isActive ? 'admin-nav-link active' : 'admin-nav-link')}
          >
            <img src={editIcon} alt="" className="admin-nav-icon" />
            Edit Requests
          </NavLink>
        </nav>
        <div className="admin-sidebar-footer">
          <button type="button" className="admin-sidebar-logout" onClick={handleLogout}>
            <img src={logoutIcon} alt="" className="admin-nav-icon" />
            Logout
          </button>
        </div>
      </aside>
      <main className="admin-main">
        <EditRequestsProvider>
          <Outlet />
        </EditRequestsProvider>
      </main>
    </div>
  )
}
