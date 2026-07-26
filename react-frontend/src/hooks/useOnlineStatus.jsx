import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';

/**
 * Hook that detects online/offline status.
 * When coming back online, it dispatches an 'app-online' custom event
 * that components can listen to for triggering a data sync.
 */
export const useOnlineStatus = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      window.dispatchEvent(new CustomEvent('app-online'));
    };
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return isOnline;
};

/**
 * Offline banner component — render at the top of the app layout.
 */
export const OfflineBanner = () => {
  const isOnline = useOnlineStatus();
  const { t } = useTranslation();

  if (isOnline) return null;

  return (
    <div style={{
      background: '#FFF8E1',
      color: '#F57C00',
      padding: '0.5rem 1rem',
      textAlign: 'center',
      fontSize: '0.8rem',
      borderBottom: '1px solid #FFE082',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '0.5rem',
      zIndex: 1000,
    }}>
      <span>📵</span>
      {t('offlineMessage')}
    </div>
  );
};
