import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { departmentsAPI } from '../api';
import { Building, Plus, Edit, Trash2, Search, Shield } from 'lucide-react';
import { toast } from 'react-toastify';
import './DepartmentManagement.css';

const DepartmentManagement = () => {
  const { isGeneralAdmin } = useAuth();
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingDept, setEditingDept] = useState(null);
  const [search, setSearch] = useState('');
  
  const [formData, setFormData] = useState({
    name: '',
    code: '',
    description: '',
  });

  useEffect(() => {
    loadDepartments();
  }, []);

  const loadDepartments = async () => {
    try {
      setLoading(true);
      const response = await departmentsAPI.list();
      setDepartments(response.data.results || response.data);
    } catch (error) {
      console.error('Error loading departments:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleOpenModal = (dept = null) => {
    if (dept) {
      setEditingDept(dept);
      setFormData({
        name: dept.name,
        code: dept.code,
        description: dept.description || '',
      });
    } else {
      setEditingDept(null);
      setFormData({
        name: '',
        code: '',
        description: '',
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingDept(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      if (editingDept) {
        await departmentsAPI.update(editingDept.id, formData);
        toast.success('Département modifié avec succès!');
      } else {
        await departmentsAPI.create(formData);
        toast.success('Département créé avec succès!');
      }
      handleCloseModal();
      loadDepartments();
    } catch (error) {
      console.error('Error saving department:', error);
      toast.error('Erreur lors de l\'enregistrement');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce département?')) {
      try {
        await departmentsAPI.delete(id);
        loadDepartments();
        toast.success('Département supprimé avec succès!');
      } catch (error) {
        console.error('Error deleting department:', error);
        toast.error('Erreur lors de la suppression');
      }
    }
  };

  const filteredDepts = departments.filter(d => 
    d.name.toLowerCase().includes(search.toLowerCase()) ||
    d.code.toLowerCase().includes(search.toLowerCase())
  );

  if (!isGeneralAdmin) {
    return (
      <div className="access-denied">
        <Shield size={48} />
        <h2>Accès refusé</h2>
        <p>Seul l'Admin Général peut gérer les départements</p>
      </div>
    );
  }

  return (
    <div className="depts-page">
      <div className="page-header">
        <h1>Gestion des Départements</h1>
        <button className="btn-primary" onClick={() => handleOpenModal()}>
          <Plus size={18} />
          Nouveau Département
        </button>
      </div>

      <div className="search-bar">
        <Search size={18} />
        <input
          type="text"
          placeholder="Rechercher un département..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {loading ? (
        <div className="loading">Chargement...</div>
      ) : (
        <div className="depts-grid">
          {filteredDepts.map(dept => (
            <div key={dept.id} className="dept-card">
              <div className="dept-icon">
                <Building size={24} />
              </div>
              <div className="dept-info">
                <h3>{dept.name}</h3>
                <span className="dept-code">{dept.code}</span>
                {dept.description && <p>{dept.description}</p>}
              </div>
              <div className="dept-actions">
                <button className="btn-edit" onClick={() => handleOpenModal(dept)}>
                  <Edit size={14} />
                </button>
                <button className="btn-delete" onClick={() => handleDelete(dept.id)}>
                  <Trash2 size={14} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={handleCloseModal}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>{editingDept ? 'Modifier le département' : 'Nouveau département'}</h2>
            
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Nom du département *</label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  placeholder="Ex: Informatique"
                  required
                />
              </div>

              <div className="form-group">
                <label>Code *</label>
                <input
                  type="text"
                  name="code"
                  value={formData.code}
                  onChange={handleInputChange}
                  placeholder="Ex: INFO"
                  required
                />
              </div>

              <div className="form-group">
                <label>Description</label>
                <textarea
                  name="description"
                  value={formData.description}
                  onChange={handleInputChange}
                  placeholder="Description du département..."
                  rows={3}
                />
              </div>

              <div className="modal-actions">
                <button type="button" className="btn-cancel" onClick={handleCloseModal}>
                  Annuler
                </button>
                <button type="submit" className="btn-submit">
                  {editingDept ? 'Enregistrer' : 'Créer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default DepartmentManagement;
