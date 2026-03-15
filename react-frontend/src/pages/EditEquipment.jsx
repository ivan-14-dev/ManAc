import { useState, useEffect, useRef } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { equipmentAPI, departmentsAPI } from '../api';
import { Plus, Package, Camera, Save, Trash2, ArrowLeft, Upload, X, Edit } from 'lucide-react';
import { toast } from 'react-toastify';
import './AddEquipment.css';

const EditEquipment = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const { isAdmin } = useAuth();
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(true);
  const [imagePreview, setImagePreview] = useState(null);
  const [imageFile, setImageFile] = useState(null);
  const fileInputRef = useRef(null);
  
  const [formData, setFormData] = useState({
    name: '',
    category: '',
    description: '',
    department: '',
    status: 'available',
    serial_number: '',
    location: '',
    total_quantity: 1,
    available_quantity: 1,
  });

  const categories = [
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
    'Camera',
    'Other',
  ];

  useEffect(() => {
    loadData();
  }, [id]);

  const loadData = async () => {
    try {
      setFetching(true);
      
      // Load departments and equipment in parallel
      const [deptRes, equipmentRes] = await Promise.all([
        departmentsAPI.list(),
        equipmentAPI.get(id)
      ]);
      
      const deptData = deptRes.data.results || deptRes.data;
      const equipmentData = equipmentRes.data;
      
      setDepartments(deptData);
      
      // Set form data with existing equipment
      setFormData({
        name: equipmentData.name || '',
        category: equipmentData.category || '',
        description: equipmentData.description || '',
        department: equipmentData.department || '',
        status: equipmentData.status || 'available',
        serial_number: equipmentData.serial_number || '',
        location: equipmentData.location || '',
        total_quantity: equipmentData.total_quantity || 1,
        available_quantity: equipmentData.available_quantity || 1,
      });
      
      // Set image preview if exists
      if (equipmentData.photo) {
        setImagePreview(equipmentData.photo);
      }
    } catch (error) {
      console.error('Error loading equipment:', error);
      toast.error('Erreur lors du chargement de l\'équipement');
      navigate('/equipment');
    } finally {
      setFetching(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: name === 'total_quantity' || name === 'available_quantity' 
        ? parseInt(value) || 0 
        : value,
    });
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

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.name || !formData.category) {
      toast.warn('Veuillez remplir le nom et la catégorie');
      return;
    }

    setLoading(true);

    try {
      const data = new FormData();
      data.append('name', formData.name);
      data.append('category', formData.category);
      data.append('description', formData.description || '');
      data.append('department', formData.department);
      data.append('status', formData.status);
      data.append('serial_number', formData.serial_number);
      data.append('location', formData.location);
      data.append('total_quantity', formData.total_quantity);
      data.append('available_quantity', formData.available_quantity);
      
      if (imageFile) {
        data.append('photo', imageFile);
      }
      
      await equipmentAPI.update(id, data);

      toast.success('Équipement modifié avec succès!');
      navigate('/equipment');
    } catch (error) {
      console.error('Error updating equipment:', error);
      toast.error('Erreur lors de la modification de l\'équipement');
    } finally {
      setLoading(false);
    }
  };

  if (fetching) {
    return <div className="loading">Chargement...</div>;
  }

  return (
    <div className="add-equipment-page">
      <div className="page-header">
        <button className="btn-back" onClick={() => navigate('/equipment')}>
          <ArrowLeft size={18} />
          Retour
        </button>
        <h1>Modifier l'Équipement</h1>
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
              <select
                name="category"
                value={formData.category}
                onChange={handleInputChange}
                required
              >
                <option value="">Sélectionner une catégorie</option>
                {categories.map(cat => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label>Département</label>
              <select
                name="department"
                value={formData.department}
                onChange={handleInputChange}
              >
                {departments.map(dept => (
                  <option key={dept.id} value={dept.id}>{dept.name}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Statut</label>
              <select
                name="status"
                value={formData.status}
                onChange={handleInputChange}
              >
                <option value="available">Disponible</option>
                <option value="checked_out">Emprunté</option>
                <option value="maintenance">Maintenance</option>
                <option value="retired">Retiré</option>
              </select>
            </div>

            <div className="form-group">
              <label>Quantité totale</label>
              <input
                type="number"
                name="total_quantity"
                value={formData.total_quantity}
                onChange={handleInputChange}
                min="1"
              />
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

        {/* Equipment Details */}
        <div className="form-section">
          <h3>IDENTIFICATION</h3>
          
          <div className="form-row">
            <div className="form-group">
              <label>Numéro de série</label>
              <input
                type="text"
                name="serial_number"
                value={formData.serial_number}
                onChange={handleInputChange}
                placeholder="Numéro de série"
              />
            </div>

            <div className="form-group">
              <label>Localisation</label>
              <input
                type="text"
                name="location"
                value={formData.location}
                onChange={handleInputChange}
                placeholder="Ex: Salle B101, Armoire A2"
              />
            </div>
          </div>
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
                Enregistrer les modifications
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default EditEquipment;
