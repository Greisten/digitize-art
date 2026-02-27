import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Digitize.art',
      'welcome_title': 'Welcome to Digitize.art',
      'welcome_subtitle': 'Professional artwork digitization in your pocket',
      'select_language': 'Select your language',
      'continue': 'Continue',
      'skip': 'Skip',
      'get_started': 'Get Started',
      
      // Onboarding
      'onboarding_1_title': 'Capture Your Art',
      'onboarding_1_desc': 'Use your smartphone camera to scan paintings, drawings, and sculptures with precision',
      'onboarding_2_title': 'AI-Powered Enhancement',
      'onboarding_2_desc': 'Automatic edge detection, perspective correction, and quality enhancement',
      'onboarding_3_title': 'Professional Export',
      'onboarding_3_desc': 'Export in high-quality formats and sync to cloud storage',
      
      // Language selection
      'choose_language': 'Choose Language',
      'language_en': 'English',
      'language_fr': 'Français',
      'language_es': 'Español',
      'language_de': 'Deutsch',
      'language_it': 'Italiano',
      
      // Camera screen
      'camera_title': 'Capture',
      'capture': 'Capture',
      'gallery': 'Gallery',
      'settings': 'Settings',
      'flash': 'Flash',
      'grid': 'Grid',
      'ar_guide': 'AR Guide',
      
      // Permissions
      'permission_camera_title': 'Camera Permission',
      'permission_camera_desc': 'We need camera access to capture your artwork',
      'permission_storage_title': 'Storage Permission',
      'permission_storage_desc': 'We need storage access to save your digitized artwork',
      'grant_permission': 'Grant Permission',
      'permission_denied': 'Permission Denied',
      
      // Errors
      'error_camera_init': 'Failed to initialize camera',
      'error_capture': 'Failed to capture image',
      'error_processing': 'Failed to process image',
      
      // Generic
      'ok': 'OK',
      'cancel': 'Cancel',
      'retry': 'Retry',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'share': 'Share',
      'close': 'Close',
      
      // Settings
      'visit_website': 'Visit Website',
      'about_app': 'About Digitize.art',
      'contact': 'Contact',
      'social_media': 'Social Media',
      
      // Auth
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'sign_out': 'Sign Out',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'full_name': 'Full Name',
      'create_account': 'Create Account',
      'sign_in_subtitle': 'Welcome back to Digitize.art',
      'sign_up_subtitle': 'Join Digitize.art today',
      'or_continue_with': 'Or continue with',
      'no_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'agree_terms': 'I agree to the Terms of Service and Privacy Policy',
      'forgot_password': 'Forgot Password?',
      'profile': 'Profile',
    },
    'fr': {
      'app_name': 'Digitize.art',
      'welcome_title': 'Bienvenue sur Digitize.art',
      'welcome_subtitle': 'Numérisation professionnelle d\'œuvres d\'art dans votre poche',
      'select_language': 'Sélectionnez votre langue',
      'continue': 'Continuer',
      'skip': 'Passer',
      'get_started': 'Commencer',
      
      // Onboarding
      'onboarding_1_title': 'Capturez Votre Art',
      'onboarding_1_desc': 'Utilisez l\'appareil photo de votre smartphone pour numériser peintures, dessins et sculptures avec précision',
      'onboarding_2_title': 'Amélioration par IA',
      'onboarding_2_desc': 'Détection automatique des bords, correction de perspective et amélioration de la qualité',
      'onboarding_3_title': 'Export Professionnel',
      'onboarding_3_desc': 'Exportez en formats haute qualité et synchronisez vers le cloud',
      
      // Language selection
      'choose_language': 'Choisir la Langue',
      'language_en': 'English',
      'language_fr': 'Français',
      'language_es': 'Español',
      'language_de': 'Deutsch',
      'language_it': 'Italiano',
      
      // Camera screen
      'camera_title': 'Capture',
      'capture': 'Capturer',
      'gallery': 'Galerie',
      'settings': 'Paramètres',
      'flash': 'Flash',
      'grid': 'Grille',
      'ar_guide': 'Guide AR',
      
      // Permissions
      'permission_camera_title': 'Permission Caméra',
      'permission_camera_desc': 'Nous avons besoin d\'accéder à la caméra pour capturer vos œuvres',
      'permission_storage_title': 'Permission Stockage',
      'permission_storage_desc': 'Nous avons besoin d\'accéder au stockage pour sauvegarder vos œuvres numérisées',
      'grant_permission': 'Accorder la Permission',
      'permission_denied': 'Permission Refusée',
      
      // Errors
      'error_camera_init': 'Échec de l\'initialisation de la caméra',
      'error_capture': 'Échec de la capture d\'image',
      'error_processing': 'Échec du traitement d\'image',
      
      // Generic
      'ok': 'OK',
      'cancel': 'Annuler',
      'retry': 'Réessayer',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'share': 'Partager',
      'close': 'Fermer',
      
      // Settings
      'visit_website': 'Visiter le Site Web',
      'about_app': 'À Propos de Digitize.art',
      'contact': 'Contact',
      'social_media': 'Réseaux Sociaux',
      
      // Auth
      'sign_in': 'Se Connecter',
      'sign_up': 'S\'inscrire',
      'sign_out': 'Se Déconnecter',
      'email': 'Email',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'full_name': 'Nom Complet',
      'create_account': 'Créer un Compte',
      'sign_in_subtitle': 'Bon retour sur Digitize.art',
      'sign_up_subtitle': 'Rejoignez Digitize.art aujourd\'hui',
      'or_continue_with': 'Ou continuer avec',
      'no_account': "Pas encore de compte?",
      'already_have_account': 'Vous avez déjà un compte?',
      'agree_terms': 'J\'accepte les Conditions d\'Utilisation et la Politique de Confidentialité',
      'forgot_password': 'Mot de passe oublié?',
      'profile': 'Profil',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters
  String get appName => translate('app_name');
  String get welcomeTitle => translate('welcome_title');
  String get welcomeSubtitle => translate('welcome_subtitle');
  String get selectLanguage => translate('select_language');
  String get continueText => translate('continue');
  String get skip => translate('skip');
  String get getStarted => translate('get_started');
  
  String get onboarding1Title => translate('onboarding_1_title');
  String get onboarding1Desc => translate('onboarding_1_desc');
  String get onboarding2Title => translate('onboarding_2_title');
  String get onboarding2Desc => translate('onboarding_2_desc');
  String get onboarding3Title => translate('onboarding_3_title');
  String get onboarding3Desc => translate('onboarding_3_desc');
  
  String get chooseLanguage => translate('choose_language');
  String get languageEn => translate('language_en');
  String get languageFr => translate('language_fr');
  String get languageEs => translate('language_es');
  String get languageDe => translate('language_de');
  String get languageIt => translate('language_it');
  
  String get cameraTitle => translate('camera_title');
  String get capture => translate('capture');
  String get gallery => translate('gallery');
  String get settings => translate('settings');
  
  String get ok => translate('ok');
  String get cancel => translate('cancel');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'es', 'de', 'it'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
