import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { equipmentAPI, departmentsAPI } from '../api';
import { Package, Plus, Edit, Trash2 } from 'lucide-react';
import { toast } from 'react-toastify';
import './EquipmentList.css';

const EquipmentList = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [equipment, setEquipment] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    category: '',
    status: '',
    department: '',
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      // Filter out empty values from filters
      const filteredParams = Object.fromEntries(
        Object.entries(filters).filter(([_, value]) => value !== '' && value !== null && value !== undefined)
      );
      
      const [equipmentRes, departmentsRes] = await Promise.all([
        equipmentAPI.list(filteredParams),
        departmentsAPI.list(),
      ]);
      
      // Handle paginated response
      const equipmentData = equipmentRes.data.results || equipmentRes.data;
      const departmentsData = departmentsRes.data.results || departmentsRes.data;
      
      setEquipment(equipmentData);
      setDepartments(departmentsData);
    } catch (error) {
      console.error('Error loading equipment:', error);
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

  const handleFilterSubmit = (e) => {
    e.preventDefault();
    setLoading(true);
    loadData();
  };

  const handleDelete = async (id) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cet équipement?')) {
      try {
        await equipmentAPI.delete(id);
        setEquipment(equipment.filter(e => e.id !== id));
        toast.success('Équipement supprimé avec succès!');
      } catch (error) {
        console.error('Error deleting equipment:', error);
        toast.error('Erreur lors de la suppression');
      }
    }
  };

  if (loading) {
    return <div className="loading">Chargement...</div>;
  }

  return (
    <div className="equipment-page">
      <div className="page-header">
        <h1>Équipements</h1>
        {isAdmin && (
          <button className="btn-primary" onClick={() => navigate('/equipment/add')}>
            <Plus size={18} />
            Ajouter
          </button>
        )}
      </div>

      <form className="filters" onSubmit={handleFilterSubmit}>
        <select name="category" value={filters.category} onChange={handleFilterChange}>
          <option value="">Toutes les catégories</option>
          <option value="Computer">Computer</option>
          <option value="Monitor">Monitor</option>
          <option value="Keyboard">Keyboard</option>
          <option value="Mouse">Mouse</option>
          <option value="Printer">Printer</option>
          <option value="Scanner">Scanner</option>
          <option value="Projector">Projector</option>
          <option value="Network Equipment">Network Equipment</option>
          <option value="Camera">Camera</option>
          <option value="Other">Other</option>
        </select>

        <select name="status" value={filters.status} onChange={handleFilterChange}>
          <option value="">Tous les statuts</option>
          <option value="available">Disponible</option>
          <option value="checked_out">Emprunté</option>
          <option value="maintenance">Maintenance</option>
          <option value="retired">Retiré</option>
        </select>

        <select name="department" value={filters.department} onChange={handleFilterChange}>
          <option value="">Tous les départements</option>
          {departments && departments.map(dept => (
            <option key={dept.id} value={dept.id}>{dept.name}</option>
          ))}
        </select>

        <button type="submit">Filtrer</button>
      </form>

      <div className="equipment-grid">
        {equipment.map(item => (
          <div key={item.id} className="equipment-card">
            <div className="equipment-info">
              <h3>{item.name}</h3>
              <p className="serial">S/N: {item.serial_number}</p>
              <p className="category">{item.category}</p>
              <p className="location">📍 {item.location}</p>
              <p className="department">{item.department_name}</p>
            </div>
            <div className="equipment-stats">
              <span className={`status ${item.status}`}>{item.status}</span>
              <p className="quantity">
                {item.available_quantity} / {item.total_quantity} disponible(s)
              </p>
              {isAdmin && (
                <div className="actions">
                  <button onClick={() => navigate(`/equipment/${item.id}/edit`)}>
                    <Edit size={16} /> Modifier
                  </button>
                  <button className="btn-danger" onClick={() => handleDelete(item.id)}>
                    <Trash2 size={16} /> Supprimer
                  </button>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {equipment.length === 0 && (
        <p className="no-data">Aucun équipement trouvé</p>
      )}
    </div>
  );
};

export default EquipmentList;
