class AppConstants {
  static const String appName = 'بيع واشتري';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String adsCollection = 'ads';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String favoritesCollection = 'favorites';
  
  // Storage Paths
  static const String adsImagesPath = 'ads_images';
  static const String profileImagesPath = 'profile_images';
  
  // Categories
  static const List<String> categories = [
    'سيارات',
    'عقارات',
    'إلكترونيات',
    'أثاث',
    'ملابس',
    'أجهزة منزلية',
    'موبايلات',
    'ألعاب',
    'حيوانات',
    'أخرى',
  ];
  
  // Cities
  static const List<String> cities = [
    'دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'دير الزور',
    'الرقة',
    'السويداء',
    'درعا',
    'إدلب',
    'القنيطرة',
    'الحسكة',
    'ريف دمشق',
  ];
} 