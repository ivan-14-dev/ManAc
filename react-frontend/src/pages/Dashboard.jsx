import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useTranslation } from 'react-i18next';
import { equipmentAPI, borrowingsAPI, departmentsAPI } from '../api';
import {
  Package, ArrowLeftRight, Building2, CheckCircle, Clock, XCircle,
  ArrowRight, AlertTriangle, Plus, RefreshCw
} from 'lucide-react';
import './Dashboard.css';

const Dashboard = () => {
  const { user, isGeneralAdmin, isDepartmentAdmin, isAdmin } = useAuth();
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    totalEquipment: 0,
    availableEquipment: 0,
    pendingBorrowings: 0,
    totalDepartments: 0,
    myBorrowingsCount: 0,
  });
  const [recentBorrowings, setRecentBorrowings] = useState([]);
  const [myBorrowings, setMyBorrowings] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, [user]);

  const loadDashboardData = async () => {
    try {
      setLoading(true);

      const promises = [
        equipmentAPI.list(),
        isAdmin
          ? borrowingsAPI.list({ status: 'pending' })
          : borrowingsAPI.myBorrowings(),
      ];

      if (isGeneralAdmin) {
        promises.push(departmentsAPI.list());
      }

      const results = await Promise.all(promises);
      const equipment = results[0].data.results || results[0].data;
      const borrowingsData = results[1].data.results || results[1].data;
      const departments = isGeneralAdmin ? (results[2]?.data || []) : [];

      let filteredPending = borrowingsData;
      if (isDepartmentAdmin && user?.department) {
        filteredPending = borrowingsData.filter(
          (b) => b.equipment_department === user.department || !b.equipment_department
        );
      }

      setStats({
        totalEquipment: equipment.length,
        availableEquipment: equipment.filter((e) => e.status === 'available').length,
        pendingBorrowings: isAdmin ? filteredPending.length : 0,
        totalDepartments: isGeneralAdmin ? departments.length : 1,
        myBorrowingsCount: !isAdmin ? borrowingsData.length : 0,
      });

      if (isAdmin) {
        setRecentBorrowings(filteredPending.slice(0, 5));
      } else {
        // For regular users: show all their borrowings sorted by date
        const sorted = [...borrowingsData].sort(
          (a, b) => new Date(b.request_date || b.created_at) - new Date(a.request_date || a.created_at)
        );
        setMyBorrowings(sorted.slice(0, 8));
      }
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusConfig = (status) => {
    const configs = {
      pending:    { label: t('statusPending'),    cls: 'pending',    icon: Clock },
      approved:   { label: t('statusApproved'),   cls: 'approved',   icon: CheckCircle },
      rejected:   { label: t('statusRejected'),   cls: 'rejected',   icon: XCircle },
      checked_out:{ label: t('statusCheckedOut'), cls: 'checked-out',icon: ArrowRight },
      returned:   { label: t('statusReturned'),   cls: 'returned',   icon: CheckCircle },
      overdue:    { label: t('statusOverdue'),    cls: 'overdue',    icon: AlertTriangle },
    };
    return configs[status] || configs.pending;
  };

  if (loading) {
    return <div className="loading">{t('loading')}</div>;
  }

  return (
    <div className="dashboard">
      <div className="welcome-section">
        <h1>{t('welcomeBack', { name: user?.first_name || user?.username })}</h1>
        <p>{t('dashboardSubtitle')}</p>
      </div>

      {/* Stats grid */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon blue"><Package size={24} /></div>
          <div className="stat-content">
            <h3>{t('totalEquipment')}</h3>
            <p className="stat-number">{stats.totalEquipment}</p>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon green"><CheckCircle size={24} /></div>
          <div className="stat-content">
            <h3>{t('available')}</h3>
            <p className="stat-number">{stats.availableEquipment}</p>
          </div>
        </div>

        {isAdmin && (
          <div className="stat-card">
            <div className="stat-icon orange"><Clock size={24} /></div>
            <div className="stat-content">
              <h3>{t('pending')}</h3>
              <p className="stat-number">{stats.pendingBorrowings}</p>
            </div>
          </div>
        )}

        {!isAdmin && (
          <div className="stat-card">
            <div className="stat-icon orange"><ArrowLeftRight size={24} /></div>
            <div className="stat-content">
              <h3>{t('myBorrowings')}</h3>
              <p className="stat-number">{stats.myBorrowingsCount}</p>
            </div>
          </div>
        )}

        {isGeneralAdmin && (
          <div className="stat-card">
            <div className="stat-icon purple"><Building2 size={24} /></div>
            <div className="stat-content">
              <h3>{t('departments')}</h3>
              <p className="stat-number">{stats.totalDepartments}</p>
            </div>
          </div>
        )}
      </div>

      {/* Admin: pending borrowings */}
      {isAdmin && (
        <div className="recent-section">
          <div className="section-header">
            <h2>{t('pendingBorrowings')}</h2>
            <div className="section-actions">
              <button className="btn-icon" onClick={loadDashboardData} title="Refresh">
                <RefreshCw size={16} />
              </button>
              <button className="btn-primary-sm" onClick={() => navigate('/borrowings')}>
                {t('borrowingsTitle')} →
              </button>
            </div>
          </div>
          {recentBorrowings.length === 0 ? (
            <div className="empty-state">
              <CheckCircle size={48} />
              <p>{t('noPendingBorrowings')}</p>
            </div>
          ) : (
            <div className="borrowings-list">
              {recentBorrowings.map((borrowing) => {
                const cfg = getStatusConfig(borrowing.status);
                const Icon = cfg.icon;
                return (
                  <div key={borrowing.id} className="borrowing-item">
                    <div className="borrowing-info">
                      <h4>{borrowing.equipment_name}</h4>
                      <p>{borrowing.borrower_name} • {borrowing.quantity} item(s)</p>
                    </div>
                    <span className={`status ${cfg.cls}`}>
                      <Icon size={16} />
                      {cfg.label}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Regular user: my borrowings */}
      {!isAdmin && (
        <div className="recent-section">
          <div className="section-header">
            <h2>{t('myBorrowings')}</h2>
            <div className="section-actions">
              <button className="btn-icon" onClick={loadDashboardData} title="Refresh">
                <RefreshCw size={16} />
              </button>
              <button className="btn-primary-sm" onClick={() => navigate('/checkout')}>
                <Plus size={14} /> {t('newBorrowing')}
              </button>
            </div>
          </div>
          <p className="section-subtitle">{t('myBorrowingsSubtitle')}</p>
          {myBorrowings.length === 0 ? (
            <div className="empty-state">
              <Package size={48} />
              <p>{t('noBorrowings')}</p>
              <button className="btn-primary-sm" onClick={() => navigate('/checkout')}>
                {t('newBorrowing')}
              </button>
            </div>
          ) : (
            <div className="my-borrowings-list">
              {myBorrowings.map((borrowing) => {
                const cfg = getStatusConfig(borrowing.status);
                const Icon = cfg.icon;
                const reqDate = borrowing.request_date
                  ? new Date(borrowing.request_date).toLocaleDateString(i18n.language)
                  : '-';
                return (
                  <div key={borrowing.id} className={`my-borrowing-card status-${cfg.cls}`}>
                    <div className="card-status-bar" />
                    <div className="card-body">
                      <div className="card-left">
                        <div className="card-equipment">{borrowing.equipment_name}</div>
                        <div className="card-meta">
                          <span>#{borrowing.reference_number || borrowing.id}</span>
                          <span>{t('units', { count: borrowing.quantity })}</span>
                          <span>{reqDate}</span>
                        </div>
                        {borrowing.expected_return_date && (
                          <div className="card-return">
                            {t('expectedReturn')} {new Date(borrowing.expected_return_date).toLocaleDateString(i18n.language)}
                          </div>
                        )}
                        {borrowing.status === 'rejected' && borrowing.notes && (
                          <div className="card-reason">
                            <XCircle size={12} /> {borrowing.notes}
                          </div>
                        )}
                      </div>
                      <div className="card-right">
                        <span className={`status-badge ${cfg.cls}`}>
                          <Icon size={14} />
                          {cfg.label}
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Dashboard;
