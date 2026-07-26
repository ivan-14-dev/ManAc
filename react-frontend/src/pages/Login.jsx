import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useTranslation } from 'react-i18next';
import { Package, Lock, User, Globe } from 'lucide-react';
import './Login.css';

const LANGUAGES = [
  { code: 'fr', label: 'Français' },
  { code: 'en', label: 'English' },
];

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();
  const { t, i18n } = useTranslation();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await login(username, password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || t('invalidCredentials'));
    } finally {
      setLoading(false);
    }
  };

  const changeLanguage = (lng) => {
    i18n.changeLanguage(lng);
    localStorage.setItem('manac_language', lng);
  };

  return (
    <div className="login-container">
      <div className="login-box">
        {/* Language switcher */}
        <div className="lang-switcher">
          <Globe size={14} />
          {LANGUAGES.map((lang) => (
            <button
              key={lang.code}
              className={`lang-btn${i18n.language === lang.code ? ' active' : ''}`}
              onClick={() => changeLanguage(lang.code)}
              type="button"
            >
              {lang.label}
            </button>
          ))}
        </div>

        <div className="login-header">
          <div className="login-logo">
            <Package size={40} />
          </div>
          <h1>{t('appName')}</h1>
          <p>{t('appSubtitle')}</p>
        </div>

        {error && <div className="error-message">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>{t('username')}</label>
            <div className="input-wrapper">
              <User size={18} className="input-icon" />
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder={t('username')}
                required
                autoComplete="username"
              />
            </div>
          </div>

          <div className="form-group">
            <label>{t('password')}</label>
            <div className="input-wrapper">
              <Lock size={18} className="input-icon" />
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={t('password')}
                required
                autoComplete="current-password"
              />
            </div>
          </div>

          <div className="forgot-link">
            <Link to="/forgot-password">{t('forgotPassword')}</Link>
          </div>

          <button type="submit" disabled={loading} className="login-btn">
            {loading ? t('loggingIn') : t('login')}
          </button>
        </form>
      </div>
    </div>
  );
};

export default Login;
