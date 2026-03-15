import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import EquipmentList from './pages/EquipmentList';
import EquipmentCheckout from './pages/EquipmentCheckout';
import Borrowings from './pages/Borrowings';
import AddEquipment from './pages/AddEquipment';
import EditEquipment from './pages/EditEquipment';
import Alerts from './pages/Alerts';
import UserManagement from './pages/UserManagement';
import DepartmentManagement from './pages/DepartmentManagement';
import './App.css';

const ProtectedRoute = ({ children }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  if (!user) {
    return <Navigate to="/login" />;
  }

  return children;
};

const AdminRoute = ({ children }) => {
  const { user, isAdmin, loading } = useAuth();

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  if (!user) {
    return <Navigate to="/login" />;
  }

  if (!isAdmin) {
    return <Navigate to="/" />;
  }

  return children;
};

const GeneralAdminRoute = ({ children }) => {
  const { user, isGeneralAdmin, loading } = useAuth();

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  if (!user) {
    return <Navigate to="/login" />;
  }

  if (!isGeneralAdmin) {
    return <Navigate to="/" />;
  }

  return children;
};

const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Layout>
              <Dashboard />
            </Layout>
          </ProtectedRoute>
        }
      />
      
      <Route
        path="/equipment"
        element={
          <ProtectedRoute>
            <Layout>
              <EquipmentList />
            </Layout>
          </ProtectedRoute>
        }
      />
      
      <Route
        path="/equipment/add"
        element={
          <AdminRoute>
            <Layout>
              <AddEquipment />
            </Layout>
          </AdminRoute>
        }
      />
      
      <Route
        path="/equipment/:id/edit"
        element={
          <AdminRoute>
            <Layout>
              <EditEquipment />
            </Layout>
          </AdminRoute>
        }
      />
      
      <Route
        path="/checkout"
        element={
          <ProtectedRoute>
            <Layout>
              <EquipmentCheckout />
            </Layout>
          </ProtectedRoute>
        }
      />
      
      <Route
        path="/borrowings"
        element={
          <ProtectedRoute>
            <Layout>
              <Borrowings />
            </Layout>
          </ProtectedRoute>
        }
      />
      
      <Route
        path="/alerts"
        element={
          <ProtectedRoute>
            <Layout>
              <Alerts />
            </Layout>
          </ProtectedRoute>
        }
      />
      
      <Route
        path="/users"
        element={
          <AdminRoute>
            <Layout>
              <UserManagement />
            </Layout>
          </AdminRoute>
        }
      />
      
      <Route
        path="/departments"
        element={
          <GeneralAdminRoute>
            <Layout>
              <DepartmentManagement />
            </Layout>
          </GeneralAdminRoute>
        }
      />
    </Routes>
  );
};

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ToastContainer position="top-right" autoClose={3000} />
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
