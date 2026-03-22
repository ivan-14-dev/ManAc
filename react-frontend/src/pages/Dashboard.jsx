import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { equipmentAPI, borrowingsAPI, departmentsAPI } from '../api';
import { Package, ArrowLeftRight, Building2, CheckCircle, Clock, XCircle } from 'lucide-react';
import './Dashboard.css';

const Dashboard = () => {
  const { user, isGeneralAdmin, isDepartmentAdmin } = useAuth();
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
  }, [user]);

  const loadDashboardData = async () => {
    try {
      // Build filters based on user role
      const equipmentParams = {};
      if (isDepartmentAdmin && user?.department) {
        equipmentParams.department = user.department;
      }
      
      const [equipmentRes, borrowingsRes, departmentsRes] = await Promise.all([
        equipmentAPI.list(equipmentParams),
        borrowingsAPI.list({ status: 'pending' }),
        departmentsAPI.list(),
      ]);

      const equipment = equipmentRes.data.results || equipmentRes.data;
      const borrowings = borrowingsRes.data.results || borrowingsRes.data;

      // Filter borrowings by department for department admin
      let filteredBorrowings = borrowings;
      if (isDepartmentAdmin && user?.department) {
        filteredBorrowings = borrowings.filter(b => 
          b.equipment_department === user.department || 
          !b.equipment_department
        );
      }

      setStats({
        totalEquipment: equipment.length,
        availableEquipment: equipment.filter(e => e.status === 'available').length,
        pendingBorrowings: filteredBorrowings.length,
        totalDepartments: isGeneralAdmin ? departmentsRes.data.length : 1,
      });

      setRecentBorrowings(filteredBorrowings.slice(0, 5));
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
      case 'checked_out': return <ArrowRight size={16} />;
      case 'returned': return <CheckCircle size={16} />;
      default: return <Clock size={16} />;
    }
  };

  const getStatusLabel = (status) => {
    const statusLabels = {
      pending: 'En attente',
      approved: 'Approuvé',
      rejected: 'Rejeté',
      checked_out: 'Emprunté',
      returned: 'Retourné',
    };
    return statusLabels[status] || status;
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
        <h2>{isGeneralAdmin ? 'Pending Borrowings' : isDepartmentAdmin ? 'Emprunts en attente - Votre département' : 'Mes demandes d\'emprunt'}</h2>
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
                  {getStatusLabel(borrowing.status)}
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
