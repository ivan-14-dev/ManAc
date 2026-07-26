import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useTranslation } from 'react-i18next';
import { OfflineBanner } from '../hooks/useOnlineStatus';
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
  PlusCircle,
  Globe,
} from 'lucide-react';
import './Layout.css';

const LANGUAGES = [
  { code: 'fr', label: 'FR' },
  { code: 'en', label: 'EN' },
];

const Layout = ({ children }) => {
  const { user, logout, isAdmin, isGeneralAdmin } = useAuth();
  const { t, i18n } = useTranslation();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const changeLanguage = (lng) => {
    i18n.changeLanguage(lng);
    localStorage.setItem('manac_language', lng);
  };

  const menuItems = [
    { path: '/', icon: LayoutDashboard, label: t('dashboard') },
    { path: '/equipment', icon: Package, label: t('equipment') },
    { path: '/checkout', icon: ShoppingCart, label: t('newBorrowing') },
    { path: '/borrowings', icon: ArrowLeftRight, label: t('borrowings') },
    { path: '/alerts', icon: Bell, label: t('alerts') },
  ];

  const adminItems = [];
  if (isAdmin) {
    adminItems.push({ path: '/equipment/add', icon: PlusCircle, label: t('addEquipment') });
  }
  if (isGeneralAdmin) {
    adminItems.push({ path: '/departments', icon: Building2, label: t('departments') });
  }
  if (isAdmin) {
    adminItems.push({ path: '/users', icon: Users, label: t('users') });
  }

  const roleLabel = user?.role === 'general_admin' ? t('roleGeneralAdmin')
    : user?.role === 'department_admin' ? t('roleDepartmentAdmin')
    : t('roleUser');

  return (
    <div className="app-container">
      {/* Offline banner */}
      <OfflineBanner />

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
          {/* Language switcher in sidebar */}
          <div className="lang-row">
            <Globe size={14} />
            {LANGUAGES.map((lang) => (
              <button
                key={lang.code}
                className={`lang-pill${i18n.language === lang.code ? ' active' : ''}`}
                onClick={() => changeLanguage(lang.code)}
                type="button"
              >
                {lang.label}
              </button>
            ))}
          </div>

          <div className="user-info">
            <div className="user-avatar">
              {user?.first_name?.[0] || user?.username?.[0] || 'U'}
            </div>
            <div className="user-details">
              <span className="user-name">{user?.first_name || user?.username}</span>
              <span className="user-role">{roleLabel}</span>
            </div>
          </div>
          <button className="logout-btn" onClick={logout}>
            <LogOut size={18} />
            <span>{t('logout')}</span>
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
             t('dashboard')}
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
