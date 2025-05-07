class AppConstants {
  static const String appName = 'بيع واشتري';
  
  // Supabase Tables
  static const String usersTable = 'users';
  static const String adsTable = 'ads';
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String favoritesTable = 'favorites';
  
  // Storage Buckets
  static const String adsImagesBucket = 'ads_images';
  static const String profileImagesBucket = 'profile_images';
  
  // Categories
  static const List<String> category = [
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
  
  // city
  static const List<String> city = [
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