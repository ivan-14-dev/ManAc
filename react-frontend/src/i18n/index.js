import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

const resources = {
  fr: {
    translation: {
      // Auth
      appName: 'ManAC',
      appSubtitle: 'Gestion des équipements du campus',
      username: 'Nom d\'utilisateur',
      password: 'Mot de passe',
      login: 'Se connecter',
      loggingIn: 'Connexion...',
      logout: 'Déconnexion',
      forgotPassword: 'Mot de passe oublié ?',
      forgotPasswordTitle: 'Réinitialiser le mot de passe',
      forgotPasswordSubtitle: 'Entrez votre email ou nom d\'utilisateur pour recevoir un code de réinitialisation',
      emailOrUsername: 'Email ou nom d\'utilisateur',
      sendCode: 'Envoyer le code',
      sending: 'Envoi...',
      enterCode: 'Entrez le code reçu par email',
      resetCode: 'Code de réinitialisation (6 chiffres)',
      verifyCode: 'Vérifier le code',
      verifying: 'Vérification...',
      newPassword: 'Nouveau mot de passe',
      confirmPassword: 'Confirmer le mot de passe',
      resetPassword: 'Réinitialiser',
      resetting: 'Réinitialisation...',
      backToLogin: 'Retour à la connexion',
      codeSent: 'Un code de réinitialisation a été envoyé à votre adresse email.',
      codeVerified: 'Code vérifié ! Entrez votre nouveau mot de passe.',
      passwordReset: 'Mot de passe réinitialisé avec succès !',
      passwordsDoNotMatch: 'Les mots de passe ne correspondent pas.',
      passwordTooShort: 'Le mot de passe doit contenir au moins 8 caractères.',
      invalidCredentials: 'Identifiants incorrects',
      enterUsernameAndPassword: 'Veuillez entrer votre nom d\'utilisateur et mot de passe',

      // Navigation
      dashboard: 'Tableau de bord',
      equipment: 'Équipements',
      borrowings: 'Emprunts',
      alerts: 'Alertes',
      users: 'Utilisateurs',
      departments: 'Départements',
      newBorrowing: 'Nouvel Emprunt',

      // Dashboard
      welcomeBack: 'Bienvenue, {{name}} ! 👋',
      dashboardSubtitle: 'Voici l\'état actuel des équipements de votre campus.',
      totalEquipment: 'Équipements',
      available: 'Disponibles',
      pending: 'En attente',
      departments: 'Départements',
      myBorrowings: 'Mes emprunts',
      myBorrowingsSubtitle: 'Statut de vos demandes d\'emprunt',
      noBorrowings: 'Aucun emprunt. Faites une nouvelle demande !',
      pendingBorrowings: 'Emprunts en attente',
      noPendingBorrowings: 'Aucun emprunt en attente. Tout est à jour !',

      // Status
      statusPending: 'En attente',
      statusApproved: 'Approuvé',
      statusRejected: 'Rejeté',
      statusCheckedOut: 'Emprunté',
      statusReturned: 'Retourné',
      statusOverdue: 'En retard',

      // Borrowings
      borrowingsTitle: 'Gestion des Emprunts',
      approve: 'Approuver',
      reject: 'Rejeter',
      checkout: 'Remettre',
      return: 'Retour',
      rejectionReason: 'Raison du rejet',
      returnNotes: 'Notes de retour (optionnel)',
      total: 'Total',
      active: 'Actifs',
      returned: 'Retournés',
      borrower: 'Emprunteur',
      quantity: 'Quantité',
      room: 'Salle',
      date: 'Date',
      status: 'Statut',
      actions: 'Actions',
      noBorrowingsFound: 'Aucun emprunt trouvé',
      searchPlaceholder: 'Rechercher par nom, CNI ou salle...',
      allStatuses: 'Tous les statuts',
      allEquipment: 'Tous les équipements',
      exportCSV: 'CSV',
      exportPDF: 'PDF',

      // Equipment
      equipmentTitle: 'Liste des Équipements',
      addEquipment: 'Ajouter un équipement',
      name: 'Nom',
      category: 'Catégorie',
      department: 'Département',
      stockQuantity: 'Quantité',
      availableQuantity: 'Disponible',
      noEquipmentFound: 'Aucun équipement trouvé',

      // Errors
      error: 'Erreur',
      success: 'Succès',
      loading: 'Chargement...',

      // Extra i18n keys
      expectedReturn: 'Retour prévu :',
      units: '{{count}} unité(s)',
      resendCode: 'Renvoyer le code',
      codeFormatError: 'Le code doit contenir exactement 6 chiffres.',
      roleGeneralAdmin: 'Admin Général',
      roleDepartmentAdmin: 'Admin Dépt.',
      roleUser: 'Utilisateur',

      // Offline
      offlineMode: 'Mode hors ligne',
      offlineMessage: 'Vous êtes hors ligne. Les modifications seront synchronisées à la reconnexion.',
      syncPending: 'Synchronisation en attente...',
      syncComplete: 'Données synchronisées !',
    },
  },
  en: {
    translation: {
      // Auth
      appName: 'ManAC',
      appSubtitle: 'Campus Equipment Management',
      username: 'Username',
      password: 'Password',
      login: 'Sign In',
      loggingIn: 'Signing in...',
      logout: 'Logout',
      forgotPassword: 'Forgot password?',
      forgotPasswordTitle: 'Reset Password',
      forgotPasswordSubtitle: 'Enter your email or username to receive a reset code',
      emailOrUsername: 'Email or username',
      sendCode: 'Send Code',
      sending: 'Sending...',
      enterCode: 'Enter the code received by email',
      resetCode: 'Reset Code (6 digits)',
      verifyCode: 'Verify Code',
      verifying: 'Verifying...',
      newPassword: 'New Password',
      confirmPassword: 'Confirm Password',
      resetPassword: 'Reset Password',
      resetting: 'Resetting...',
      backToLogin: 'Back to Login',
      codeSent: 'A reset code has been sent to your email address.',
      codeVerified: 'Code verified! Enter your new password.',
      passwordReset: 'Password reset successfully!',
      passwordsDoNotMatch: 'Passwords do not match.',
      passwordTooShort: 'Password must be at least 8 characters.',
      invalidCredentials: 'Invalid credentials',
      enterUsernameAndPassword: 'Please enter your username and password',

      // Navigation
      dashboard: 'Dashboard',
      equipment: 'Equipment',
      borrowings: 'Borrowings',
      alerts: 'Alerts',
      users: 'Users',
      departments: 'Departments',
      newBorrowing: 'New Borrowing',

      // Dashboard
      welcomeBack: 'Welcome back, {{name}}! 👋',
      dashboardSubtitle: "Here's what's happening with your campus equipment today.",
      totalEquipment: 'Total Equipment',
      available: 'Available',
      pending: 'Pending',
      departments: 'Departments',
      myBorrowings: 'My Borrowings',
      myBorrowingsSubtitle: 'Status of your borrowing requests',
      noBorrowings: 'No borrowings yet. Make a new request!',
      pendingBorrowings: 'Pending Borrowings',
      noPendingBorrowings: 'No pending borrowings! All caught up.',

      // Status
      statusPending: 'Pending',
      statusApproved: 'Approved',
      statusRejected: 'Rejected',
      statusCheckedOut: 'Checked Out',
      statusReturned: 'Returned',
      statusOverdue: 'Overdue',

      // Borrowings
      borrowingsTitle: 'Borrowings Management',
      approve: 'Approve',
      reject: 'Reject',
      checkout: 'Check Out',
      return: 'Return',
      rejectionReason: 'Rejection reason',
      returnNotes: 'Return notes (optional)',
      total: 'Total',
      active: 'Active',
      returned: 'Returned',
      borrower: 'Borrower',
      quantity: 'Quantity',
      room: 'Room',
      date: 'Date',
      status: 'Status',
      actions: 'Actions',
      noBorrowingsFound: 'No borrowings found',
      searchPlaceholder: 'Search by name, ID or room...',
      allStatuses: 'All statuses',
      allEquipment: 'All equipment',
      exportCSV: 'CSV',
      exportPDF: 'PDF',

      // Equipment
      equipmentTitle: 'Equipment List',
      addEquipment: 'Add Equipment',
      name: 'Name',
      category: 'Category',
      department: 'Department',
      stockQuantity: 'Quantity',
      availableQuantity: 'Available',
      noEquipmentFound: 'No equipment found',

      // Errors
      error: 'Error',
      success: 'Success',
      loading: 'Loading...',

      // Extra i18n keys
      expectedReturn: 'Expected return:',
      units: '{{count}} unit(s)',
      resendCode: 'Resend code',
      codeFormatError: 'The code must be exactly 6 digits.',
      roleGeneralAdmin: 'General Admin',
      roleDepartmentAdmin: 'Dept. Admin',
      roleUser: 'User',

      // Offline
      offlineMode: 'Offline Mode',
      offlineMessage: 'You are offline. Changes will be synced when you reconnect.',
      syncPending: 'Syncing...',
      syncComplete: 'Data synced!',
    },
  },
};

const savedLang = localStorage.getItem('manac_language') || 'fr';

i18n
  .use(initReactI18next)
  .init({
    resources,
    lng: savedLang,
    fallbackLng: 'fr',
    interpolation: {
      escapeValue: false,
    },
  });

export default i18n;
