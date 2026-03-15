import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  LayoutDashboard, 
  Package, 
  ArrowLeftRight, 
  Building2, 
  Users,
  Menu,
  X,
  LogOut,
  Bell,
  ShoppingCart,
  PlusCircle
} from 'lucide-react';
import './Layout.css';

const Layout = ({ children }) => {
  const { user, logout, isAdmin, isGeneralAdmin } = useAuth();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const menuItems = [
    { path: '/', icon: LayoutDashboard, label: 'Dashboard' },
    { path: '/equipment', icon: Package, label: 'Équipements' },
    { path: '/checkout', icon: ShoppingCart, label: 'Emprunter' },
    { path: '/borrowings', icon: ArrowLeftRight, label: 'Emprunts' },
    { path: '/alerts', icon: Bell, label: 'Alertes' },
  ];

  // Admin-only menu items
  const adminItems = [];
  if (isAdmin) {
    adminItems.push({ path: '/equipment/add', icon: PlusCircle, label: 'Ajouter Équip.' });
  }
  if (isGeneralAdmin) {
    adminItems.push({ path: '/departments', icon: Building2, label: 'Départements' });
  }
  if (isAdmin) {
    adminItems.push({ path: '/users', icon: Users, label: 'Utilisateurs' });
  }

  return (
    <div className="app-container">
      {/* Sidebar - Desktop */}
      <aside className={`sidebar ${sidebarOpen ? 'open' : 'closed'}`}>
        <div className="sidebar-header">
          <div className="logo">
            <Package size={28} />
            <span>ManAC</span>
          </div>
          <button className="toggle-btn" onClick={() => setSidebarOpen(!sidebarOpen)}>
            {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>

        <nav className="sidebar-nav">
          {menuItems.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
            >
              <item.icon size={20} />
              <span>{item.label}</span>
            </Link>
          ))}
          {adminItems.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
            >
              <item.icon size={20} />
              <span>{item.label}</span>
            </Link>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-avatar">
              {user?.first_name?.[0] || user?.username?.[0] || 'U'}
            </div>
            <div className="user-details">
              <span className="user-name">{user?.first_name || user?.username}</span>
              <span className="user-role">
                {user?.role === 'general_admin' ? 'Admin Général' : 
                 user?.role === 'department_admin' ? 'Admin Dépt.' : 'Utilisateur'}
              </span>
            </div>
          </div>
          <button className="logout-btn" onClick={logout}>
            <LogOut size={18} />
            <span>Déconnexion</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        <header className="top-bar">
          <button className="menu-toggle" onClick={() => setSidebarOpen(!sidebarOpen)}>
            <Menu size={24} />
          </button>
          <div className="page-title">
            {menuItems.find(item => item.path === location.pathname)?.label || 
             adminItems.find(item => item.path === location.pathname)?.label || 
             'Dashboard'}
          </div>
          <div className="top-bar-actions">
            <span className="user-badge">
              {user?.department_name || 'Tous les départements'}
            </span>
          </div>
        </header>
        <div className="content-wrapper">
          {children}
        </div>
      </main>

      {/* Bottom Navigation - Mobile */}
      <nav className="bottom-nav">
        <div className="bottom-nav-items">
          {menuItems.slice(0, 5).map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`bottom-nav-item ${location.pathname === item.path ? 'active' : ''}`}
            >
              <item.icon size={24} />
              <span>{item.label}</span>
            </Link>
          ))}
        </div>
      </nav>
    </div>
  );
};

export default Layout;
