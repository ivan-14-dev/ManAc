import axios from 'axios';

// Use environment variable or default to local development
const API_URL = import.meta.env.VITE_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true, // Enable session-based auth
});

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
  login: (credentials) => api.post('/auth/login/', credentials),
  logout: () => api.post('/auth/logout/'),
  me: () => api.get('/users/me/'),
};

// Departments API
export const departmentsAPI = {
  list: (params) => api.get('/departments/', { params }),
  get: (id) => api.get(`/departments/${id}/`),
  create: (data) => api.post('/departments/', data),
  update: (id, data) => api.put(`/departments/${id}/`, data),
  delete: (id) => api.delete(`/departments/${id}/`),
};

// Equipment API
export const equipmentAPI = {
  list: (params) => api.get('/equipment/', { params }),
  get: (id) => api.get(`/equipment/${id}/`),
  create: (data) => api.post('/equipment/', data),
  update: (id, data) => api.put(`/equipment/${id}/`, data),
  delete: (id) => api.delete(`/equipment/${id}/`),
  available: () => api.get('/equipment/available/'),
  history: (id) => api.get(`/equipment/${id}/history/`),
};

// Borrowings API
export const borrowingsAPI = {
  list: (params) => api.get('/borrowings/', { params }),
  get: (id) => api.get(`/borrowings/${id}/`),
  create: (data) => api.post('/borrowings/', data),
  update: (id, data) => api.put(`/borrowings/${id}/`, data),
  delete: (id) => api.delete(`/borrowings/${id}/`),
  approve: (id) => api.post(`/borrowings/${id}/approve/`),
  reject: (id, data) => api.post(`/borrowings/${id}/reject/`, data),
  checkout: (id) => api.post(`/borrowings/${id}/checkout/`),
  return: (id, data) => api.post(`/borrowings/${id}/return_equipment/`, data),
  myBorrowings: () => api.get('/borrowings/my_borrowings/'),
  pending: () => api.get('/borrowings/pending/'),
  overdue: () => api.get('/borrowings/overdue/'),
};

// Users API
export const usersAPI = {
  list: () => api.get('/users/'),
  get: (id) => api.get(`/users/${id}/`),
  create: (data) => api.post('/users/', data),
  update: (id, data) => api.put(`/users/${id}/`, data),
  delete: (id) => api.delete(`/users/${id}/`),
};

export default api;
