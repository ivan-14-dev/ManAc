import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { usersAPI, departmentsAPI } from '../api';
import { Users, Plus, Edit, Trash2, Search, Shield, User, Building } from 'lucide-react';
import { toast } from 'react-toastify';
import './UserManagement.css';

const UserManagement = () => {
  const { isAdmin, isGeneralAdmin, user: currentUser } = useAuth();
  const [users, setUsers] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [search, setSearch] = useState('');
  
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    first_name: '',
    last_name: '',
    role: 'user',
    department: '',
    password: '',
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [usersRes, deptsRes] = await Promise.all([
        usersAPI.list(),
        departmentsAPI.list(),
      ]);
      
      setUsers(usersRes.data.results || usersRes.data);
      setDepartments(deptsRes.data.results || deptsRes.data);
      
      if (deptsRes.data.results) {
        setFormData(prev => ({ ...prev, department: deptsRes.data.results[0]?.id || '' }));
      }
    } catch (error) {
      console.error('Error loading data:', error);
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

  const handleOpenModal = (user = null) => {
    if (user) {
      setEditingUser(user);
      setFormData({
        username: user.username,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        department: user.department,
        password: '',
      });
    } else {
      setEditingUser(null);
      setFormData({
        username: '',
        email: '',
        first_name: '',
        last_name: '',
        role: 'user',
        department: departments[0]?.id || '',
        password: '',
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingUser(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      // Prepare data - ensure department is an integer
      const data = {
        ...formData,
        department: formData.department ? parseInt(formData.department) : null,
      };
      
      if (editingUser) {
        // Update user
        const updateData = { ...data };
        if (!updateData.password) delete updateData.password;
        await usersAPI.update(editingUser.id, updateData);
        toast.success('Utilisateur modifié avec succès!');
      } else {
        // Create user
        await usersAPI.create(data);
        toast.success('Utilisateur créé avec succès!');
      }
      handleCloseModal();
      loadData();
    } catch (error) {
      console.error('Error saving user:', error);
      const errorMsg = error.response?.data?.detail || error.response?.data?.message || 'Erreur lors de l\'enregistrement';
      toast.error(errorMsg);
    }
  };

  const handleDelete = async (id) => {
    if (id === currentUser?.id) {
      toast.warn('Vous ne pouvez pas supprimer votre propre compte');
      return;
    }
    
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cet utilisateur?')) {
      try {
        await usersAPI.delete(id);
        loadData();
        toast.success('Utilisateur supprimé avec succès!');
      } catch (error) {
        console.error('Error deleting user:', error);
        toast.error('Erreur lors de la suppression');
      }
    }
  };

  const filteredUsers = users.filter(u => {
    const searchLower = search.toLowerCase();
    return (
      u.username.toLowerCase().includes(searchLower) ||
      u.email.toLowerCase().includes(searchLower) ||
      (u.first_name && u.first_name.toLowerCase().includes(searchLower)) ||
      (u.last_name && u.last_name.toLowerCase().includes(searchLower))
    );
  });

  const getRoleBadge = (role) => {
    const roles = {
      general_admin: { label: 'Admin Général', class: 'admin' },
      department_admin: { label: 'Admin Dépt.', class: 'dept-admin' },
      user: { label: 'Utilisateur', class: 'user' },
    };
    const config = roles[role] || roles.user;
    return <span className={`role-badge ${config.class}`}>{config.label}</span>;
  };

  const getDepartmentName = (deptId) => {
    const dept = departments.find(d => d.id === deptId);
    return dept ? dept.name : '-';
  };

  if (!isAdmin) {
    return (
      <div className="access-denied">
        <Shield size={48} />
        <h2>Accès refusé</h2>
        <p>Vous n'avez pas l'autorisation d'accéder à cette page</p>
      </div>
    );
  }

  return (
    <div className="users-page">
      <div className="page-header">
        <h1>Gestion des Utilisateurs</h1>
        <button className="btn-primary" onClick={() => handleOpenModal()}>
          <Plus size={18} />
          Nouvel Utilisateur
        </button>
      </div>

      <div className="search-bar">
        <Search size={18} />
        <input
          type="text"
          placeholder="Rechercher un utilisateur..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {loading ? (
        <div className="loading">Chargement...</div>
      ) : (
        <div className="users-table">
          <table>
            <thead>
              <tr>
                <th>Utilisateur</th>
                <th>Email</th>
                <th>Rôle</th>
                <th>Département</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map(user => (
                <tr key={user.id}>
                  <td>
                    <div className="user-cell">
                      <div className="user-avatar">
                        {user.first_name?.[0] || user.username[0]}
                      </div>
                      <div>
                        <strong>{user.first_name} {user.last_name}</strong>
                        <span>@{user.username}</span>
                      </div>
                    </div>
                  </td>
                  <td>{user.email}</td>
                  <td>{getRoleBadge(user.role)}</td>
                  <td>
                    <span className="dept-name">
                      <Building size={14} />
                      {getDepartmentName(user.department)}
                    </span>
                  </td>
                  <td>
                    <div className="action-buttons">
                      <button className="btn-edit" onClick={() => handleOpenModal(user)}>
                        <Edit size={14} />
                      </button>
                      {user.id !== currentUser?.id && (
                        <button className="btn-delete" onClick={() => handleDelete(user.id)}>
                          <Trash2 size={14} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={handleCloseModal}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2>{editingUser ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur'}</h2>
            
            <form onSubmit={handleSubmit}>
              <div className="form-row">
                <div className="form-group">
                  <label>Prénom</label>
                  <input
                    type="text"
                    name="first_name"
                    value={formData.first_name}
                    onChange={handleInputChange}
                  />
                </div>
                <div className="form-group">
                  <label>Nom</label>
                  <input
                    type="text"
                    name="last_name"
                    value={formData.last_name}
                    onChange={handleInputChange}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Nom d'utilisateur *</label>
                <input
                  type="text"
                  name="username"
                  value={formData.username}
                  onChange={handleInputChange}
                  required
                />
              </div>

              <div className="form-group">
                <label>Email *</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  required
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Rôle *</label>
                  <select name="role" value={formData.role} onChange={handleInputChange}>
                    <option value="user">Utilisateur</option>
                    {isGeneralAdmin && (
                      <>
                        <option value="department_admin">Admin Département</option>
                        <option value="general_admin">Admin Général</option>
                      </>
                    )}
                  </select>
                </div>

                <div className="form-group">
                  <label>Département</label>
                  <select name="department" value={formData.department} onChange={handleInputChange}>
                    {departments.map(dept => (
                      <option key={dept.id} value={dept.id}>{dept.name}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label>
                  {editingUser ? 'Nouveau mot de passe (laisser vide pour garder l\'actuel)' : 'Mot de passe *'}
                </label>
                <input
                  type="password"
                  name="password"
                  value={formData.password}
                  onChange={handleInputChange}
                  required={!editingUser}
                />
              </div>

              <div className="modal-actions">
                <button type="button" className="btn-cancel" onClick={handleCloseModal}>
                  Annuler
                </button>
                <button type="submit" className="btn-submit">
                  {editingUser ? 'Enregistrer' : 'Créer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserManagement;
