import axios from 'axios';

// Use environment variable or default to local development
const API_URL = import.meta.env.VITE_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
  withCredentials: true, // Enable session-based auth
});

// Request interceptor to handle Content-Type
api.interceptors.request.use(
  (config) => {
    // Only set Content-Type if not FormData
    if (!(config.data instanceof FormData)) {
      config.headers['Content-Type'] = 'application/json';
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Handle auth responses
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  login: (credentials) => api.post('/api/auth/login/', credentials),
  logout: () => api.post('/api/auth/logout/'),
  me: () => api.get('/api/auth/me/'),
};

// Departments API
export const departmentsAPI = {
  list: (params) => api.get('/api/departments/', { params }),
  get: (id) => api.get(`/api/departments/${id}/`),
  create: (data) => api.post('/api/departments/', data),
  update: (id, data) => api.put(`/api/departments/${id}/`, data),
  delete: (id) => api.delete(`/api/departments/${id}/`),
};

// Equipment API
export const equipmentAPI = {
  list: (params) => api.get('/api/equipment/', { params }),
  get: (id) => api.get(`/api/equipment/${id}/`),
  create: (data) => api.post('/api/equipment/', data),
  update: (id, data) => api.put(`/api/equipment/${id}/`, data),
  delete: (id) => api.delete(`/api/equipment/${id}/`),
  available: () => api.get('/api/equipment/available/'),
  history: (id) => api.get(`/api/equipment/${id}/history/`),
  exportCSV: () => api.get('/api/equipment/export_csv/', { responseType: 'blob' }),
  exportPDF: () => api.get('/api/equipment/export_pdf/', { responseType: 'blob' }),
};

// Borrowings API
export const borrowingsAPI = {
  list: (params) => api.get('/api/borrowings/', { params }),
  get: (id) => api.get(`/api/borrowings/${id}/`),
  create: (data) => api.post('/api/borrowings/', data),
  update: (id, data) => api.put(`/api/borrowings/${id}/`, data),
  delete: (id) => api.delete(`/api/borrowings/${id}/`),
  approve: (id) => api.post(`/api/borrowings/${id}/approve/`),
  reject: (id, data) => api.post(`/api/borrowings/${id}/reject/`, data),
  checkout: (id) => api.post(`/api/borrowings/${id}/checkout/`),
  return: (id, data) => api.post(`/api/borrowings/${id}/return_equipment/`, data),
  myBorrowings: () => api.get('/api/borrowings/my_borrowings/'),
  pending: () => api.get('/api/borrowings/pending/'),
  overdue: () => api.get('/api/borrowings/overdue/'),
  exportCSV: () => api.get('/api/borrowings/export_csv/', { responseType: 'blob' }),
  exportPDF: () => api.get('/api/borrowings/export_pdf/', { responseType: 'blob' }),
};

// Users API
export const usersAPI = {
  list: () => api.get('/api/users/'),
  get: (id) => api.get(`/api/users/${id}/`),
  create: (data) => api.post('/api/users/', data),
  update: (id, data) => api.put(`/api/users/${id}/`, data),
  delete: (id) => api.delete(`/api/users/${id}/`),
};

// Activities API
export const activitiesAPI = {
  list: (params) => api.get('/api/activities/', { params }),
  get: (id) => api.get(`/api/activities/${id}/`),
  create: (data) => api.post('/api/activities/', data),
};

// Stock API
export const stockAPI = {
  list: (params) => api.get('/api/stock/', { params }),
  get: (id) => api.get(`/api/stock/${id}/`),
  create: (data) => api.post('/api/stock/', data),
  update: (id, data) => api.put(`/api/stock/${id}/`, data),
  delete: (id) => api.delete(`/api/stock/${id}/`),
  lowStock: () => api.get('/api/stock/low_stock/'),
};

// Stock Movements API
export const stockMovementsAPI = {
  list: (params) => api.get('/api/stock-movements/', { params }),
  get: (id) => api.get(`/api/stock-movements/${id}/`),
  create: (data) => api.post('/api/stock-movements/', data),
};

// Reports API
export const reportsAPI = {
  list: (params) => api.get('/api/reports/', { params }),
  get: (id) => api.get(`/api/reports/${id}/`),
  generate: (date) => api.post('/api/reports/generate/', { date }),
  recent: (days = 7) => api.get(`/api/reports/recent/?days=${days}`),
};

export default api;
