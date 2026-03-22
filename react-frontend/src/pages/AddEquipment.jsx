import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { equipmentAPI, departmentsAPI } from '../api';
import { Plus, Package, Camera, Save, Trash2, ArrowLeft, Upload, X } from 'lucide-react';
import { toast } from 'react-toastify';
import './AddEquipment.css';

const AddEquipment = () => {
  const navigate = useNavigate();
  const { isAdmin, isDepartmentAdmin, user } = useAuth();
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [entries, setEntries] = useState([]);
  const [imagePreview, setImagePreview] = useState(null);
  const [imageFile, setImageFile] = useState(null);
  const fileInputRef = useRef(null);
  
  const [formData, setFormData] = useState({
    name: '',
    category: '',
    description: '',
    department: '',
    status: 'available',
  });

  const [entryData, setEntryData] = useState({
    serial_number: '',
    location: '',
  });

  const defaultCategories = [
    'Computer',
    'Monitor',
    'Keyboard',
    'Mouse',
    'Printer',
    'Scanner',
    'Projector',
    'Network Equipment',
    'Cables',
    'Accessories',
    'Other',
  ];

  const [categories, setCategories] = useState(defaultCategories);
  const [newCategory, setNewCategory] = useState('');
  const [showNewCategoryInput, setShowNewCategoryInput] = useState(false);

  useEffect(() => {
    loadDepartments();
  }, []);

  const loadDepartments = async () => {
    try {
      const response = await departmentsAPI.list();
      let data = response.data.results || response.data;
      
      // Filter departments for department admin - only show their own department
      if (isDepartmentAdmin && user?.department) {
        data = data.filter(d => d.id === user.department);
      }
      
      setDepartments(data);
      if (data.length > 0) {
        // If department admin, force their department
        const defaultDept = isDepartmentAdmin && user?.department 
          ? user.department 
          : data[0].id;
        setFormData(prev => ({ ...prev, department: defaultDept }));
      }
    } catch (error) {
      console.error('Error loading departments:', error);
    }
  };

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleAddNewCategory = () => {
    if (newCategory.trim() && !categories.includes(newCategory.trim())) {
      const categoryToAdd = newCategory.trim();
      setCategories([...categories, categoryToAdd]);
      setFormData({ ...formData, category: categoryToAdd });
      setNewCategory('');
      setShowNewCategoryInput(false);
    }
  };

  const handleCategoryChange = (e) => {
    if (e.target.value === '__new__') {
      setShowNewCategoryInput(true);
      setFormData({ ...formData, category: '' });
    } else {
      setShowNewCategoryInput(false);
      setFormData({ ...formData, category: e.target.value });
    }
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const removeImage = () => {
    setImageFile(null);
    setImagePreview(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleEntryChange = (e) => {
    setEntryData({
      ...entryData,
      [e.target.name]: e.target.value,
    });
  };

  const handleAddEntry = () => {
    if (!entryData.serial_number.trim() || !entryData.location.trim()) {
      toast.warn('Veuillez remplir le numéro de série et la localisation');
      return;
    }

    setEntries([...entries, { ...entryData }]);
    setEntryData({ serial_number: '', location: '' });
  };

  const handleRemoveEntry = (index) => {
    setEntries(entries.filter((_, i) => i !== index));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.name || !formData.category) {
      toast.warn('Veuillez remplir le nom et la catégorie');
      return;
    }

    if (entries.length === 0) {
      toast.warn('Veuillez ajouter au moins un équipement');
      return;
    }

    setLoading(true);

    try {
      // Create each equipment entry
      for (const entry of entries) {
        const data = new FormData();
        data.append('name', formData.name);
        data.append('category', formData.category);
        data.append('description', formData.description || '');
        data.append('department', formData.department);
        data.append('status', formData.status);
        data.append('serial_number', entry.serial_number);
        data.append('location', entry.location);
        data.append('total_quantity', 1);
        data.append('available_quantity', 1);
        
        if (imageFile) {
          data.append('photo', imageFile);
        }
        
        await equipmentAPI.create(data);
      }

      toast.success(`${entries.length} équipement(s) ajouté(s) avec succès!`);
      navigate('/equipment');
    } catch (error) {
      console.error('Error adding equipment:', error);
      toast.error('Erreur lors de l\'ajout de l\'équipement');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="add-equipment-page">
      <div className="page-header">
        <button className="btn-back" onClick={() => navigate('/equipment')}>
          <ArrowLeft size={18} />
          Retour
        </button>
        <h1>Ajouter un Équipement</h1>
      </div>

      <form onSubmit={handleSubmit}>
        {/* Basic Information */}
        <div className="form-section">
          <h3>INFORMATIONS DE BASE</h3>
          
          <div className="form-group">
            <label>Nom de l'équipement *</label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              placeholder="Ex: Ordinateur Dell XPS 15"
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Catégorie *</label>
              {showNewCategoryInput ? (
                <div style={{ display: 'flex', gap: '8px' }}>
                  <input
                    type="text"
                    value={newCategory}
                    onChange={(e) => setNewCategory(e.target.value)}
                    placeholder="Nouvelle catégorie"
                    style={{ flex: 1 }}
                  />
                  <button
                    type="button"
                    onClick={handleAddNewCategory}
                    className="btn-add-small"
                    disabled={!newCategory.trim()}
                  >
                    <Plus size={16} />
                  </button>
                </div>
              ) : (
                <div style={{ display: 'flex', gap: '8px' }}>
                  <select
                    name="category"
                    value={formData.category}
                    onChange={handleCategoryChange}
                    required
                    style={{ flex: 1 }}
                  >
                    <option value="">Sélectionner une catégorie</option>
                    {categories.map(cat => (
                      <option key={cat} value={cat}>{cat}</option>
                    ))}
                    <option value="__new__" disabled>────────────────</option>
                    <option value="__new__">+ Nouvelle catégorie</option>
                  </select>
                </div>
              )}
            </div>

            <div className="form-group">
              <label>Département</label>
              <select
                name="department"
                value={formData.department}
                onChange={handleInputChange}
              >
                <option value="">Sélectionner un département</option>
                {departments.map(dept => (
                  <option key={dept.id} value={dept.id}>{dept.name}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="form-group">
            <label>Description</label>
            <textarea
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              placeholder="Description de l'équipement..."
              rows={3}
            />
          </div>

          <div className="form-group">
            <label>Photo de l'équipement</label>
            <div 
              className={`image-upload ${imagePreview ? 'has-image' : ''}`}
              onClick={() => fileInputRef.current?.click()}
            >
              <input
                type="file"
                ref={fileInputRef}
                onChange={handleImageChange}
                accept="image/*"
              />
              {!imagePreview ? (
                <div className="image-upload-label">
                  <Upload size={32} />
                  <span>Cliquez pour télécharger une image</span>
                  <span style={{fontSize: '12px', color: '#999'}}>PNG, JPG, GIF - Max 5MB</span>
                </div>
              ) : (
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
                  <img src={imagePreview} alt="Preview" className="image-preview" />
                  <button 
                    type="button" 
                    className="image-remove"
                    onClick={(e) => {
                      e.stopPropagation();
                      removeImage();
                    }}
                  >
                    <X size={14} /> Supprimer
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Equipment Entries */}
        <div className="form-section">
          <h3>IDENTIFICATION</h3>
          
          <div className="entry-form">
            <div className="form-row">
              <div className="form-group">
                <label>Numéro de série *</label>
                <input
                  type="text"
                  name="serial_number"
                  value={entryData.serial_number}
                  onChange={handleEntryChange}
                  placeholder="Numéro de série"
                />
              </div>

              <div className="form-group">
                <label>Localisation *</label>
                <input
                  type="text"
                  name="location"
                  value={entryData.location}
                  onChange={handleEntryChange}
                  placeholder="Ex: Salle B101, Armoire A2"
                />
              </div>

              <button type="button" className="btn-add-entry" onClick={handleAddEntry}>
                <Plus size={18} />
                Ajouter
              </button>
            </div>
          </div>

          {/* Entries List */}
          {entries.length > 0 && (
            <div className="entries-list">
              <h4>Équipements ajoutés ({entries.length})</h4>
              <table>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Numéro de série</th>
                    <th>Localisation</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {entries.map((entry, index) => (
                    <tr key={index}>
                      <td>{index + 1}</td>
                      <td>{entry.serial_number}</td>
                      <td>{entry.location}</td>
                      <td>
                        <button
                          type="button"
                          className="btn-remove"
                          onClick={() => handleRemoveEntry(index)}
                        >
                          <Trash2 size={14} />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        <div className="form-actions">
          <button type="button" className="btn-cancel" onClick={() => navigate('/equipment')}>
            Annuler
          </button>
          <button type="submit" className="btn-submit" disabled={loading}>
            {loading ? (
              'Enregistrement...'
            ) : (
              <>
                <Save size={18} />
                Ajouter {entries.length > 0 ? `${entries.length} équipement(s)` : 'l\'équipement'}
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default AddEquipment;
