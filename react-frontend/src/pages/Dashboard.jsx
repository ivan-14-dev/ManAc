import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { equipmentAPI, borrowingsAPI, departmentsAPI } from '../api';
import { Package, ArrowLeftRight, Building2, CheckCircle, Clock, XCircle } from 'lucide-react';
import './Dashboard.css';

const Dashboard = () => {
  const { user, isGeneralAdmin } = useAuth();
  const [stats, setStats] = useState({
    totalEquipment: 0,
    availableEquipment: 0,
    pendingBorrowings: 0,
    totalDepartments: 0,
  });
  const [recentBorrowings, setRecentBorrowings] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      const [equipmentRes, borrowingsRes, departmentsRes] = await Promise.all([
        equipmentAPI.list(),
        borrowingsAPI.pending(),
        departmentsAPI.list(),
      ]);

      const equipment = equipmentRes.data.results || equipmentRes.data;
      const borrowings = borrowingsRes.data;

      setStats({
        totalEquipment: equipment.length,
        availableEquipment: equipment.filter(e => e.status === 'available').length,
        pendingBorrowings: borrowings.length,
        totalDepartments: departmentsRes.data.length,
      });

      setRecentBorrowings(borrowings.slice(0, 5));
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'pending': return <Clock size={16} />;
      case 'approved': return <CheckCircle size={16} />;
      case 'rejected': return <XCircle size={16} />;
      default: return <Clock size={16} />;
    }
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="dashboard">
      <div className="welcome-section">
        <h1>Welcome back, {user?.first_name || user?.username}! 👋</h1>
        <p>Here's what's happening with your campus equipment today.</p>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon blue">
            <Package size={24} />
          </div>
          <div className="stat-content">
            <h3>Total Equipment</h3>
            <p className="stat-number">{stats.totalEquipment}</p>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon green">
            <CheckCircle size={24} />
          </div>
          <div className="stat-content">
            <h3>Available</h3>
            <p className="stat-number">{stats.availableEquipment}</p>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon orange">
            <Clock size={24} />
          </div>
          <div className="stat-content">
            <h3>Pending</h3>
            <p className="stat-number">{stats.pendingBorrowings}</p>
          </div>
        </div>
        
        {isGeneralAdmin && (
          <div className="stat-card">
            <div className="stat-icon purple">
              <Building2 size={24} />
            </div>
            <div className="stat-content">
              <h3>Departments</h3>
              <p className="stat-number">{stats.totalDepartments}</p>
            </div>
          </div>
        )}
      </div>

      <div className="recent-section">
        <h2>Pending Borrowings</h2>
        {recentBorrowings.length === 0 ? (
          <div className="empty-state">
            <CheckCircle size={48} />
            <p>No pending borrowings! All caught up.</p>
          </div>
        ) : (
          <div className="borrowings-list">
            {recentBorrowings.map(borrowing => (
              <div key={borrowing.id} className="borrowing-item">
                <div className="borrowing-info">
                  <h4>{borrowing.equipment_name}</h4>
                  <p>{borrowing.borrower_name} • {borrowing.quantity} item(s)</p>
                </div>
                <span className={`status ${borrowing.status}`}>
                  {getStatusIcon(borrowing.status)}
                  {borrowing.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Dashboard;
