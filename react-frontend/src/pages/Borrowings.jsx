import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { borrowingsAPI, equipmentAPI } from '../api';
import { History, Search, Filter, CheckCircle, XCircle, Clock, Package, ArrowRight, RefreshCw } from 'lucide-react';
import { toast } from 'react-toastify';
import './Borrowings.css';

const Borrowings = () => {
  const navigate = useNavigate();
  const { isAdmin, isGeneralAdmin, isDepartmentAdmin, user } = useAuth();
  const [borrowings, setBorrowings] = useState([]);
  const [equipment, setEquipment] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    status: '',
    search: '',
    start_date: '',
    end_date: '',
    equipment: '',
  });

  useEffect(() => {
    loadData();
  }, [filters, user]);

  const loadData = async () => {
    try {
      setLoading(true);
      
      // Filter out empty values from filters
      const filteredParams = Object.fromEntries(
        Object.entries(filters).filter(([_, value]) => value !== '' && value !== null && value !== undefined)
      );
      
      // Use my_borrowings for regular users, regular list for admins
      let borrowingsRes;
      if (!isAdmin) {
        borrowingsRes = await borrowingsAPI.myBorrowings();
      } else {
        borrowingsRes = await borrowingsAPI.list(filteredParams);
      }
      
      const equipmentRes = await equipmentAPI.list();
      
      const borrowingsData = borrowingsRes.data.results || borrowingsRes.data;
      const equipmentData = equipmentRes.data.results || equipmentRes.data;
      
      // Filter by department for department admin
      let filteredBorrowings = borrowingsData;
      if (isDepartmentAdmin && user?.department) {
        filteredBorrowings = borrowingsData.filter(b => 
          b.equipment_department === user.department || !b.equipment_department
        );
      }
      
      setBorrowings(filteredBorrowings);
      setEquipment(equipmentData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (e) => {
    setFilters({
      ...filters,
      [e.target.name]: e.target.value,
    });
  };

  const handleApprove = async (id) => {
    try {
      await borrowingsAPI.approve(id);
      loadData();
      toast.success('Emprunt approuvé avec succès!');
    } catch (error) {
      console.error('Error approving borrowing:', error);
      toast.error('Erreur lors de l\'approbation de l\'emprunt');
    }
  };

  const handleReject = async (id) => {
    const notes = prompt('Raison du rejet:');
    if (notes === null) return;
    try {
      await borrowingsAPI.reject(id, { rejection_reason: notes });
      loadData();
      toast.success('Emprunt rejeté');
    } catch (error) {
      console.error('Error rejecting borrowing:', error);
      toast.error('Erreur lors du rejet de l\'emprunt');
    }
  };

  const handleCheckout = async (id) => {
    try {
      await borrowingsAPI.checkout(id);
      loadData();
      toast.success('Équipement remis avec succès!');
    } catch (error) {
      console.error('Error checking out equipment:', error);
      toast.error('Erreur lors de la remise de l\'équipement');
    }
  };

  const handleReturn = async (id) => {
    const notes = prompt('Notes pour le retour (optionnel):') || '';
    try {
      await borrowingsAPI.return(id, { condition_notes: notes });
      loadData();
      toast.success('Équipement retourné avec succès!');
    } catch (error) {
      console.error('Error returning equipment:', error);
      toast.error('Erreur lors du retour de l\'équipement');
    }
  };

  const getStatusBadge = (status) => {
    const statusConfig = {
      pending: { label: 'En attente', class: 'pending', icon: Clock },
      approved: { label: 'Approuvé', class: 'approved', icon: CheckCircle },
      rejected: { label: 'Rejeté', class: 'rejected', icon: XCircle },
      checked_out: { label: 'Emprunté', class: 'checked-out', icon: ArrowRight },
      returned: { label: 'Retourné', class: 'returned', icon: CheckCircle },
      overdue: { label: 'En retard', class: 'overdue', icon: Clock },
    };
    
    const config = statusConfig[status] || statusConfig.pending;
    const Icon = config.icon;
    
    return (
      <span className={`status-badge ${config.class}`}>
        <Icon size={14} />
        {config.label}
      </span>
    );
  };

  const getEquipmentName = (equipmentId) => {
    const item = equipment.find(e => e.id === equipmentId);
    return item ? item.name : `Equipment #${equipmentId}`;
  };

  const stats = {
    total: borrowings.length,
    active: borrowings.filter(b => b.status === 'checked_out').length,
    returned: borrowings.filter(b => b.status === 'returned').length,
    pending: borrowings.filter(b => b.status === 'pending').length,
  };

  return (
    <div className="borrowings-page">
      <div className="page-header">
        <h1>Gestion des Emprunts</h1>
        <button className="btn-primary" onClick={() => navigate('/checkout')}>
          <Package size={18} />
          Nouvel Emprunt
        </button>
      </div>

      {/* Stats */}
      <div className="stats-row">
        <div className="stat-card">
          <History size={20} />
          <div>
            <span className="stat-value">{stats.total}</span>
            <span className="stat-label">Total</span>
          </div>
        </div>
        <div className="stat-card active">
          <Clock size={20} />
          <div>
            <span className="stat-value">{stats.pending}</span>
            <span className="stat-label">En attente</span>
          </div>
        </div>
        <div className="stat-card checked-out">
          <ArrowRight size={20} />
          <div>
            <span className="stat-value">{stats.active}</span>
            <span className="stat-label">Actifs</span>
          </div>
        </div>
        <div className="stat-card returned">
          <CheckCircle size={20} />
          <div>
            <span className="stat-value">{stats.returned}</span>
            <span className="stat-label">Retournés</span>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="filters-bar">
        <div className="search-box">
          <Search size={18} />
          <input
            type="text"
            name="search"
            placeholder="Rechercher par nom, CNI ou salle..."
            value={filters.search}
            onChange={handleFilterChange}
          />
        </div>

        <select name="status" value={filters.status} onChange={handleFilterChange}>
          <option value="">Tous les statuts</option>
          <option value="pending">En attente</option>
          <option value="approved">Approuvé</option>
          <option value="rejected">Rejeté</option>
          <option value="checked_out">Emprunté</option>
          <option value="returned">Retourné</option>
          <option value="overdue">En retard</option>
        </select>

        <select name="equipment" value={filters.equipment} onChange={handleFilterChange}>
          <option value="">Tous les équipements</option>
          {equipment.map(item => (
            <option key={item.id} value={item.id}>{item.name}</option>
          ))}
        </select>

        <div className="date-range">
          <input
            type="date"
            name="start_date"
            value={filters.start_date}
            onChange={handleFilterChange}
          />
          <span>à</span>
          <input
            type="date"
            name="end_date"
            value={filters.end_date}
            onChange={handleFilterChange}
          />
        </div>

        <button className="btn-refresh" onClick={loadData}>
          <RefreshCw size={18} />
        </button>
      </div>

      {/* Pending Approvals (Admin only) */}
      {isAdmin && stats.pending > 0 && (
        <div className="pending-section">
          <h3>Emprunts en attente d'approbation</h3>
          <div className="pending-list">
            {borrowings.filter(b => b.status === 'pending').map(item => (
              <div key={item.id} className="pending-card">
                <div className="pending-info">
                  <h4>{item.borrower_name}</h4>
                  <p>{getEquipmentName(item.equipment)} - Qté: {item.quantity}</p>
                  <p className="meta">{item.destination_room} | {item.borrower_cni}</p>
                </div>
                <div className="pending-actions">
                  <button className="btn-approve" onClick={() => handleApprove(item.id)}>
                    <CheckCircle size={16} /> Approuver
                  </button>
                  <button className="btn-reject" onClick={() => handleReject(item.id)}>
                    <XCircle size={16} /> Rejeter
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Borrowings List */}
      <div className="borrowings-list">
        {loading ? (
          <div className="loading">Chargement...</div>
        ) : borrowings.length === 0 ? (
          <div className="no-data">
            <History size={48} />
            <p>Aucun emprunt trouvé</p>
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Équipement</th>
                <th>Emprunteur</th>
                <th>Quantité</th>
                <th>Salle</th>
                <th>Date</th>
                <th>Statut</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {borrowings.map(item => (
                <tr key={item.id}>
                  <td className="id-cell">#{item.id}</td>
                  <td>{item.equipment_name || getEquipmentName(item.equipment)}</td>
                  <td>
                    <div className="borrower-info">
                      <strong>{item.borrower_name}</strong>
                      <span>{item.borrower_cni}</span>
                    </div>
                  </td>
                  <td>{item.quantity}</td>
                  <td>{item.destination_room}</td>
                  <td>
                    {item.created_at ? new Date(item.created_at).toLocaleDateString('fr-FR') : '-'}
                  </td>
                  <td>{getStatusBadge(item.status)}</td>
                  <td>
                    <div className="action-buttons">
                      {item.status === 'approved' && isAdmin && (
                        <button className="btn-action" onClick={() => handleCheckout(item.id)}>
                          <ArrowRight size={14} /> Remettre
                        </button>
                      )}
                      {item.status === 'checked_out' && isAdmin && (
                        <button className="btn-action" onClick={() => handleReturn(item.id)}>
                          <RefreshCw size={14} /> Retour
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default Borrowings;
