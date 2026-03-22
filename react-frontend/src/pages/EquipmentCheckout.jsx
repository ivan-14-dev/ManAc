import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { equipmentAPI, borrowingsAPI } from '../api';
import { ShoppingCart, User, School, Badge, History, Plus, Package, Check, Trash2, Camera, X } from 'lucide-react';
import { toast } from 'react-toastify';
import './EquipmentCheckout.css';

const EquipmentCheckout = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [step, setStep] = useState('select-type'); // select-type, select-equipment, form
  const [checkoutType, setCheckoutType] = useState(null); // student, staff
  const [equipment, setEquipment] = useState([]);
  const [selectedEquipment, setSelectedEquipment] = useState([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  
  const [formData, setFormData] = useState({
    borrower_name: '',
    borrower_cni: '',
    borrower_email: '',
    quantity_by_equipment: {}, // { equipment_id: quantity }
    destination_room: '',
    notes: '',
  });

  const [cniPhoto, setCniPhoto] = useState(null);
  const [cniPreview, setCniPreview] = useState(null);

  useEffect(() => {
    loadEquipment();
  }, []);

  const loadEquipment = async () => {
    try {
      setLoading(true);
      const response = await equipmentAPI.available();
      const data = response.data.results || response.data;
      setEquipment(data);
    } catch (error) {
      console.error('Error loading equipment:', error);
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

  const handleCniPhotoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setCniPhoto(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setCniPreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const removeCniPhoto = () => {
    setCniPhoto(null);
    setCniPreview(null);
  };

  const handleTypeSelect = (type) => {
    setCheckoutType(type);
    setStep('select-equipment');
  };

  const handleEquipmentToggle = (item) => {
    const isSelected = selectedEquipment.some(e => e.id === item.id);
    
    if (isSelected) {
      // Remove from selection
      setSelectedEquipment(selectedEquipment.filter(e => e.id !== item.id));
      const newQuantities = { ...formData.quantity_by_equipment };
      delete newQuantities[item.id];
      setFormData({ ...formData, quantity_by_equipment: newQuantities });
    } else {
      // Add to selection with default quantity of 1
      setSelectedEquipment([...selectedEquipment, item]);
      setFormData({
        ...formData,
        quantity_by_equipment: {
          ...formData.quantity_by_equipment,
          [item.id]: 1
        }
      });
    }
  };

  const handleQuantityChange = (equipmentId, value) => {
    const qty = Math.max(1, parseInt(value) || 1);
    const item = equipment.find(e => e.id === equipmentId);
    const maxQty = item ? item.available_quantity : 1;
    
    setFormData({
      ...formData,
      quantity_by_equipment: {
        ...formData.quantity_by_equipment,
        [equipmentId]: Math.min(qty, maxQty)
      }
    });
  };

  const handleEquipmentSelect = () => {
    if (selectedEquipment.length > 0) {
      setStep('form');
    } else {
      toast.warn('Veuillez sélectionner au moins un équipement');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validate
    if (!formData.borrower_name.trim() || !formData.borrower_cni.trim() || !formData.destination_room.trim()) {
      toast.warn('Veuillez remplir tous les champs obligatoires');
      return;
    }

    if (!cniPhoto) {
      toast.warn('Veuillez télécharger une photo de votre CNI');
      return;
    }

    if (Object.keys(formData.quantity_by_equipment).length === 0) {
      toast.warn('Veuillez sélectionner au moins un équipement');
      return;
    }

    setSubmitting(true);

    try {
      // Create borrowing for each selected equipment
      for (const item of selectedEquipment) {
        const quantity = formData.quantity_by_equipment[item.id] || 1;
        
        const data = new FormData();
        data.append('equipment', item.id);
        data.append('borrower_name', formData.borrower_name);
        data.append('borrower_cni', formData.borrower_cni);
        data.append('borrower_email', formData.borrower_email);
        data.append('quantity', quantity);
        data.append('destination_room', formData.destination_room);
        data.append('notes', formData.notes);
        data.append('cni_photo', cniPhoto);
        
        await borrowingsAPI.create(data);
      }

      toast.success(`${selectedEquipment.length} emprunt(s) créé(s) avec succès!`);
      
      // Reset form
      setFormData({
        borrower_name: '',
        borrower_cni: '',
        borrower_email: '',
        quantity_by_equipment: {},
        destination_room: '',
        notes: '',
      });
      setCniPhoto(null);
      setCniPreview(null);
      setSelectedEquipment([]);
      setCheckoutType(null);
      setStep('select-type');
      navigate('/borrowings');
    } catch (error) {
      console.error('Error creating borrowing:', error);
      toast.error('Erreur lors de la création de l\'emprunt');
    } finally {
      setSubmitting(false);
    }
  };

  const resetForm = () => {
    setStep('select-type');
    setCheckoutType(null);
    setSelectedEquipment([]);
    setFormData({
      borrower_name: '',
      borrower_cni: '',
      borrower_email: '',
      quantity_by_equipment: {},
      destination_room: '',
      notes: '',
    });
    setCniPhoto(null);
    setCniPreview(null);
  };

  const totalItems = Object.values(formData.quantity_by_equipment).reduce((a, b) => a + b, 0);

  return (
    <div className="checkout-page">
      <div className="page-header">
        <h1>Emprunt d'Équipement</h1>
        <button className="btn-secondary" onClick={() => navigate('/borrowings')}>
          <History size={18} />
          Voir les emprunts
        </button>
      </div>

      {/* Step 1: Select Type */}
      {step === 'select-type' && (
        <div className="type-selection">
          <h2>Quel type d'emprunt souhaitez-vous effectuer?</h2>
          
          <div className="type-cards">
            <div className="type-card" onClick={() => handleTypeSelect('student')}>
              <div className="type-icon student">
                <School size={40} />
              </div>
              <h3>Emprunt Étudiant</h3>
              <p>Pour les étudiants</p>
            </div>

            <div className="type-card" onClick={() => handleTypeSelect('staff')}>
              <div className="type-icon staff">
                <Badge size={40} />
              </div>
              <h3>Emprunt Personnel</h3>
              <p>Pour le personnel</p>
            </div>
          </div>
        </div>
      )}

      {/* Step 2: Select Equipment */}
      {step === 'select-equipment' && (
        <div className="equipment-selection">
          <div className="selection-header">
            <button className="btn-back" onClick={() => setStep('select-type')}>
              ← Retour
            </button>
            <h2>Sélectionner les équipements</h2>
            <span className="selected-count">
              {selectedEquipment.length} sélectionné(s)
            </span>
          </div>

          {loading ? (
            <div className="loading">Chargement...</div>
          ) : equipment.length === 0 ? (
            <div className="no-equipment">
              <Package size={64} />
              <p>Aucun équipement disponible</p>
            </div>
          ) : (
            <div className="equipment-list">
              {equipment.map((item) => {
                const isSelected = selectedEquipment.some(e => e.id === item.id);
                return (
                  <div 
                    key={item.id} 
                    className={`equipment-item ${isSelected ? 'selected' : ''}`}
                    onClick={() => handleEquipmentToggle(item)}
                  >
                    <div className="equipment-checkbox">
                      {isSelected && <Check size={16} />}
                    </div>
                    <div className="equipment-icon">
                      <Package size={24} />
                    </div>
                    <div className="equipment-info">
                      <h3>{item.name}</h3>
                      <p className="category">{item.category}</p>
                      <p className="available">
                        Disponible: {item.available_quantity}/{item.total_quantity}
                      </p>
                    </div>
                    {isSelected && (
                      <div className="quantity-input">
                        <input
                          type="number"
                          min="1"
                          max={item.available_quantity}
                          value={formData.quantity_by_equipment[item.id] || 1}
                          onChange={(e) => handleQuantityChange(item.id, e.target.value)}
                          onClick={(e) => e.stopPropagation()}
                        />
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}

          <div className="selection-actions">
            <button className="btn-back" onClick={() => setStep('select-type')}>
              Retour
            </button>
            <button 
              className="btn-submit" 
              onClick={handleEquipmentSelect}
              disabled={selectedEquipment.length === 0}
            >
              Confirmer ({totalItems} item(s))
            </button>
          </div>
        </div>
      )}

      {/* Step 3: Form */}
      {step === 'form' && (
        <div className="checkout-form">
          <div className="selection-header">
            <button className="btn-back" onClick={() => setStep('select-equipment')}>
              ← Retour
            </button>
            <h2>Informations de l'emprunt</h2>
          </div>

          {/* Selected Equipment Summary */}
          <div className="selected-equipment-list">
            <h3>Équipements sélectionnés ({totalItems} items)</h3>
            {selectedEquipment.map(item => (
              <div key={item.id} className="selected-item">
                <Package size={16} />
                <span>{item.name}</span>
                <span className="qty">x{formData.quantity_by_equipment[item.id] || 1}</span>
                <button 
                  type="button" 
                  className="remove-btn"
                  onClick={() => handleEquipmentToggle(item)}
                >
                  <Trash2 size={14} />
                </button>
              </div>
            ))}
          </div>

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Nom de l'emprunteur *</label>
              <input
                type="text"
                name="borrower_name"
                value={formData.borrower_name}
                onChange={handleInputChange}
                required
                placeholder="Nom complet"
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Numéro CNI *</label>
                <input
                  type="text"
                  name="borrower_cni"
                  value={formData.borrower_cni}
                  onChange={handleInputChange}
                  required
                  placeholder="Numéro de CNI"
                />
              </div>

              <div className="form-group">
                <label>Email</label>
                <input
                  type="email"
                  name="borrower_email"
                  value={formData.borrower_email}
                  onChange={handleInputChange}
                  placeholder="email@exemple.com"
                />
              </div>
            </div>

            <div className="form-group">
              <label htmlFor="cni-photo-input">Photo CNI * (Requis - Format image)</label>
              {!cniPreview && (
                <div 
                  className="cni-upload"
                  onClick={() => document.getElementById('cni-photo-input').click()}
                  style={{ cursor: 'pointer' }}
                >
                  <div className="cni-upload-label">
                    <Camera size={32} />
                    <span>Cliquez pour télécharger la photo de la CNI</span>
                    <span style={{fontSize: '12px', color: '#999'}}>PNG, JPG - Max 5MB</span>
                  </div>
                </div>
              )}
              <input
                id="cni-photo-input"
                type="file"
                accept="image/*"
                onChange={handleCniPhotoChange}
                style={{ display: cniPreview ? 'none' : 'block', marginTop: '10px', width: '100%' }}
              />
              {cniPreview && (
                <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', marginTop: '10px'}}>
                  <img src={cniPreview} alt="CNI" className="cni-preview" />
                  <button 
                    type="button" 
                    className="cni-remove"
                    onClick={removeCniPhoto}
                    style={{ marginTop: '10px' }}
                  >
                    <X size={14} /> Supprimer
                  </button>
                </div>
              )}
            </div>

            <div className="form-group">
              <label>Salle/Destination *</label>
              <input
                type="text"
                name="destination_room"
                value={formData.destination_room}
                onChange={handleInputChange}
                required
                placeholder="Salle B101"
              />
            </div>

            <div className="form-group">
              <label>Notes</label>
              <textarea
                name="notes"
                value={formData.notes}
                onChange={handleInputChange}
                placeholder="Notes supplémentaires..."
                rows={3}
              />
            </div>

            <div className="form-actions">
              <button type="button" className="btn-cancel" onClick={resetForm}>
                Annuler
              </button>
              <button type="submit" className="btn-submit" disabled={submitting}>
                {submitting ? 'Envoi...' : `Confirmer l'emprunt (${totalItems} items)`}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};

export default EquipmentCheckout;
