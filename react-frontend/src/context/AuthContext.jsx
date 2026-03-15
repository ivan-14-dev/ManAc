import { createContext, useContext, useState, useEffect } from 'react';
import { authAPI } from '../api';

const AuthContext = createContext(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is logged in on mount
    authAPI.me()
      .then(res => setUser(res.data))
      .catch(() => {
        // Not logged in
      })
      .finally(() => setLoading(false));
  }, []);

  const login = async (username, password) => {
    try {
      const response = await authAPI.login({ username, password });
      setUser(response.data);
      return response.data;
    } catch (error) {
      throw error;
    }
  };

  const logout = async () => {
    try {
      await authAPI.logout();
    } catch (error) {
      console.error('Logout error:', error);
    }
    setUser(null);
  };

  // Role checks based on Django user model
  const isAdmin = user?.role === 'general_admin' || user?.role === 'department_admin';
  const isGeneralAdmin = user?.role === 'general_admin';
  const isDepartmentAdmin = user?.role === 'department_admin';

  const value = {
    user,
    loading,
    login,
    logout,
    isAdmin,
    isGeneralAdmin,
    isDepartmentAdmin,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
