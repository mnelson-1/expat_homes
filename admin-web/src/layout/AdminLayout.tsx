import { Outlet, NavLink, useNavigate } from 'react-router-dom'

export function AdminLayout() {
  const navigate = useNavigate()

  const handleLogout = () => {
    // TODO: clear auth and redirect to login
    navigate('/admin/login')
  }

  return (
    <div className="admin-layout">
      <header className="admin-header">
        <h1 className="admin-header-title">Expat Homes – Super Admin</h1>
        <button type="button" className="admin-header-logout" onClick={handleLogout}>
          Log out
        </button>
      </header>
      <div className="admin-body">
        <aside className="admin-sidebar">
          <nav className="admin-nav">
            <NavLink
              to="/admin/listings/pending"
              className={({ isActive }) => (isActive ? 'admin-nav-link active' : 'admin-nav-link')}
            >
              Pending listings
            </NavLink>
            <NavLink
              to="/admin/edit-requests"
              className={({ isActive }) => (isActive ? 'admin-nav-link active' : 'admin-nav-link')}
            >
              Edit requests
            </NavLink>
          </nav>
        </aside>
        <main className="admin-main">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
