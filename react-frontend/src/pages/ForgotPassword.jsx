import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { authAPI } from '../api';
import { Package, Mail, KeyRound, Lock, ArrowLeft, Globe } from 'lucide-react';
import './Login.css';
import './ForgotPassword.css';

const LANGUAGES = [
  { code: 'fr', label: 'Français' },
  { code: 'en', label: 'English' },
];

// Step 1: ask email/username → Step 2: enter 6-digit code → Step 3: enter new password
const ForgotPassword = () => {
  const { t, i18n } = useTranslation();
  const [step, setStep] = useState(1);
  const [identifier, setIdentifier] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [loading, setLoading] = useState(false);

  const changeLanguage = (lng) => {
    i18n.changeLanguage(lng);
    localStorage.setItem('manac_language', lng);
  };

  const handleSendCode = async (e) => {
    e.preventDefault();
    setError('');
    setInfo('');
    setLoading(true);
    try {
      const data = identifier.includes('@')
        ? { email: identifier }
        : { username: identifier };
      await authAPI.forgotPassword(data);
      setInfo(t('codeSent'));
      setStep(2);
    } catch {
      setError(t('error'));
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyCode = async (e) => {
    e.preventDefault();
    setError('');
    setInfo('');
    if (code.length !== 6 || !/^\d{6}$/.test(code)) {
      setError(t('codeFormatError'));
      return;
    }
    setLoading(true);
    try {
      const data = identifier.includes('@')
        ? { email: identifier, code }
        : { username: identifier, code };
      await authAPI.verifyResetCode(data);
      setInfo(t('codeVerified'));
      setStep(3);
    } catch (err) {
      setError(err.response?.data?.error || t('error'));
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (e) => {
    e.preventDefault();
    setError('');
    setInfo('');
    if (newPassword !== confirmPassword) {
      setError(t('passwordsDoNotMatch'));
      return;
    }
    if (newPassword.length < 8) {
      setError(t('passwordTooShort'));
      return;
    }
    setLoading(true);
    try {
      const data = identifier.includes('@')
        ? { email: identifier, code, new_password: newPassword }
        : { username: identifier, code, new_password: newPassword };
      await authAPI.resetPassword(data);
      setInfo(t('passwordReset'));
      setStep(4);
    } catch (err) {
      setError(err.response?.data?.error || t('error'));
    } finally {
      setLoading(false);
    }
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
          <p>{t(step === 4 ? 'passwordReset' : 'forgotPasswordTitle')}</p>
        </div>

        {/* Step indicator */}
        <div className="step-indicator">
          {[1, 2, 3].map((s) => (
            <div key={s} className={`step-dot${step >= s ? ' done' : ''}${step === s ? ' active' : ''}`} />
          ))}
        </div>

        {error && <div className="error-message">{error}</div>}
        {info && <div className="success-message">{info}</div>}

        {/* Step 1: Enter email/username */}
        {step === 1 && (
          <form onSubmit={handleSendCode}>
            <p className="step-hint">{t('forgotPasswordSubtitle')}</p>
            <div className="form-group">
              <label>{t('emailOrUsername')}</label>
              <div className="input-wrapper">
                <Mail size={18} className="input-icon" />
                <input
                  type="text"
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  placeholder={t('emailOrUsername')}
                  required
                  autoFocus
                />
              </div>
            </div>
            <button type="submit" className="login-btn" disabled={loading}>
              {loading ? t('sending') : t('sendCode')}
            </button>
          </form>
        )}

        {/* Step 2: Enter 6-digit code */}
        {step === 2 && (
          <form onSubmit={handleVerifyCode}>
            <p className="step-hint">{t('enterCode')}</p>
            <div className="form-group">
              <label>{t('resetCode')}</label>
              <div className="input-wrapper">
                <KeyRound size={18} className="input-icon" />
                <input
                  type="text"
                  inputMode="numeric"
                  pattern="\d{6}"
                  maxLength={6}
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
                  placeholder="000000"
                  required
                  autoFocus
                  className="code-input"
                />
              </div>
            </div>
            <button type="submit" className="login-btn" disabled={loading}>
              {loading ? t('verifying') : t('verifyCode')}
            </button>
            <button
              type="button"
              className="resend-btn"
              onClick={() => { setStep(1); setCode(''); setError(''); setInfo(''); }}
            >
              {t('resendCode')}
            </button>
          </form>
        )}

        {/* Step 3: Enter new password */}
        {step === 3 && (
          <form onSubmit={handleResetPassword}>
            <div className="form-group">
              <label>{t('newPassword')}</label>
              <div className="input-wrapper">
                <Lock size={18} className="input-icon" />
                <input
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder={t('newPassword')}
                  required
                  autoFocus
                  autoComplete="new-password"
                />
              </div>
            </div>
            <div className="form-group">
              <label>{t('confirmPassword')}</label>
              <div className="input-wrapper">
                <Lock size={18} className="input-icon" />
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder={t('confirmPassword')}
                  required
                  autoComplete="new-password"
                />
              </div>
            </div>
            <button type="submit" className="login-btn" disabled={loading}>
              {loading ? t('resetting') : t('resetPassword')}
            </button>
          </form>
        )}

        {/* Step 4: Success */}
        {step === 4 && (
          <div className="reset-success">
            <div className="success-icon">✅</div>
            <p>{t('passwordReset')}</p>
          </div>
        )}

        <div className="back-link">
          <Link to="/login">
            <ArrowLeft size={14} />
            {t('backToLogin')}
          </Link>
        </div>
      </div>
    </div>
  );
};

export default ForgotPassword;
