import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { borrowingsAPI, equipmentAPI } from '../api';
import { Bell, Undo, Package, CheckCircle, Clock, Box, ArrowRight } from 'lucide-react';
import './Alerts.css';

const Alerts = () => {
  const navigate = useNavigate();
  const { isAdmin, isDepartmentAdmin, user } = useAuth();
  const [pendingReturns, setPendingReturns] = useState([]);
  const [lowStock, setLowStock] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAlerts();
  }, []);

  const loadAlerts = async () => {
    try {
      setLoading(true);
      
      // Build department filter for department admin
      const deptFilter = isDepartmentAdmin && user?.department ? { department: user.department } : {};
      
      // Get pending/active borrowings
      const borrowingsRes = await borrowingsAPI.list({ status: 'checked_out', ...deptFilter });
      const borrowingsData = borrowingsRes.data.results || borrowingsRes.data;
      setPendingReturns(borrowingsData);

      // Get equipment filtered by department
      const equipmentRes = await equipmentAPI.list(deptFilter);
      const equipmentData = equipmentRes.data.results || equipmentRes.data;
      
      // Filter low stock (less than 2 available)
      const lowStockItems = equipmentData.filter(e => e.available_quantity < 2 && e.available_quantity > 0);
      setLowStock(lowStockItems);
    } catch (error) {
      console.error('Error loading alerts:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleReturn = async (id) => {
    try {
      await borrowingsAPI.return(id, { condition_notes: '' });
      loadAlerts();
    } catch (error) {
      alert('Error processing return');
    }
  };

  const hasAlerts = pendingReturns.length > 0 || lowStock.length > 0;

  return (
    <div className="alerts-page">
      <div className="page-header">
        <h1>Alertes</h1>
      </div>

      {loading ? (
        <div className="loading">Chargement...</div>
      ) : !hasAlerts ? (
        <div className="no-alerts">
          <Bell size={80} />
          <h2>Aucune alerte</h2>
          <p>Tout est en ordre!</p>
        </div>
      ) : (
        <div className="alerts-container">
          {/* Pending Returns */}
          {pendingReturns.length > 0 && (
            <div className="alert-section">
              <div className="section-header">
                <Undo size={24} />
                <h2>Retours en attente</h2>
                <span className="count pending">{pendingReturns.length}</span>
              </div>
              
              <div className="alert-list">
                {pendingReturns.map(item => (
                  <div key={item.id} className="alert-card pending">
                    <div className="alert-icon">
                      <Undo size={20} />
                    </div>
                    <div className="alert-info">
                      <h4>{item.equipment_name || `Equipment #${item.equipment}`}</h4>
                      <p>{item.borrower_name} - {item.destination_room}</p>
                      <span className="quantity">Quantité: {item.quantity}</span>
                    </div>
                    {isAdmin && (
                      <button className="btn-return" onClick={() => handleReturn(item.id)}>
                        <CheckCircle size={14} /> Retour
                      </button>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Low Stock */}
          {lowStock.length > 0 && (
            <div className="alert-section">
              <div className="section-header">
                <Box size={24} />
                <h2>Stock faible</h2>
                <span className="count low-stock">{lowStock.length}</span>
              </div>
              
              <div className="alert-list">
                {lowStock.map(item => (
                  <div key={item.id} className="alert-card low-stock">
                    <div className="alert-icon">
                      <Box size={20} />
                    </div>
                    <div className="alert-info">
                      <h4>{item.name}</h4>
                      <p>{item.category}</p>
                      <span className="quantity">Disponible: {item.available_quantity}</span>
                    </div>
                    <button className="btn-view" onClick={() => navigate(`/equipment/${item.id}`)}>
                      <ArrowRight size={14} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Alerts;
