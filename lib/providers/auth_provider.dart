import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app;
import '../utils/constants.dart';


class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  app.User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  app.User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _init();
  }

  void _init() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      try {
        final userData = await _supabase
            .from(AppConstants.usersTable)
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();
            
        if (userData != null) {
          _user = app.User.fromMap(userData);
        } else {
          // Create user record if it doesn't exist
          await _supabase.from(AppConstants.usersTable).insert({
            'id': currentUser.id,
            'email': currentUser.email,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          // Fetch the newly created user
          final newUserData = await _supabase
              .from(AppConstants.usersTable)
              .select()
              .eq('id', currentUser.id)
              .single();
          _user = app.User.fromMap(newUserData);
        }
      } catch (e) {
        debugPrint('Error initializing user: $e');
      }
    }
    _isAuthenticated = _user != null;
    
    _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.session?.user != null) {
        try {
          final userData = await _supabase
              .from(AppConstants.usersTable)
              .select()
              .eq('id', data.session!.user.id)
              .maybeSingle();
              
          if (userData != null) {
            _user = app.User.fromMap(userData);
          } else {
            // Create user record if it doesn't exist
            await _supabase.from(AppConstants.usersTable).insert({
              'id': data.session!.user.id,
              'email': data.session!.user.email,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            
            // Fetch the newly created user
            final newUserData = await _supabase
                .from(AppConstants.usersTable)
                .select()
                .eq('id', data.session!.user.id)
                .single();
            _user = app.User.fromMap(newUserData);
          }
        } catch (e) {
          debugPrint('Error handling auth state change: $e');
        }
      } else {
        _user = null;
      }
      _isAuthenticated = _user != null;
      notifyListeners();
    });
  }

  Future<void> register(String email, String password, String name, String phone, String address) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (response.user != null) {
        await _supabase.from(AppConstants.usersTable).insert({
          'id': response.user!.id,
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.toString().contains('weak-password')) {
        throw Exception('كلمة المرور ضعيفة جداً');
      } else if (e.toString().contains('email-already-in-use')) {
        throw Exception('البريد الإلكتروني مستخدم بالفعل');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('البريد الإلكتروني غير صالح');
      } else {
        throw Exception('حدث خطأ أثناء التسجيل: $e');
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user != null) {
        final userData = await _supabase
            .from(AppConstants.usersTable)
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();
            
        if (userData != null) {
          _user = app.User.fromMap(userData);
        } else {
          // Create user record if it doesn't exist
          await _supabase.from(AppConstants.usersTable).insert({
            'id': response.user!.id,
            'email': response.user!.email,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          // Fetch the newly created user
          final newUserData = await _supabase
              .from(AppConstants.usersTable)
              .select()
              .eq('id', response.user!.id)
              .single();
          _user = app.User.fromMap(newUserData);
        }
        
        _isAuthenticated = true;
        notifyListeners();

        await _supabase.from(AppConstants.usersTable)
            .update({
          'last_login': DateTime.now().toIso8601String(),
        })
            .eq('id', response.user!.id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.toString().contains('user-not-found')) {
        throw Exception('لم يتم العثور على المستخدم');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception('كلمة المرور غير صحيحة');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('البريد الإلكتروني غير صالح');
      } else {
        throw Exception('حدث خطأ أثناء تسجيل الدخول: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.signOut();
      _user = null;
      _isAuthenticated = false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('حدث خطأ أثناء تسجيل الخروج: $e');
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('AuthProvider: Giriş denemesi yapılıyor - Email: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('AuthProvider: Giriş başarılı - Kullanıcı ID: ${response.user!.id}');
        
        final userData = await _supabase
            .from(AppConstants.usersTable)
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();
            
        if (userData != null) {
          _user = app.User.fromMap(userData);
        } else {
          // Create user record if it doesn't exist
          await _supabase.from(AppConstants.usersTable).insert({
            'id': response.user!.id,
            'email': response.user!.email,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          // Fetch the newly created user
          final newUserData = await _supabase
              .from(AppConstants.usersTable)
              .select()
              .eq('id', response.user!.id)
              .single();
          _user = app.User.fromMap(newUserData);
        }
        
        _isAuthenticated = true;
        notifyListeners();

        await _supabase.from(AppConstants.usersTable)
            .update({
          'last_login': DateTime.now().toIso8601String(),
        })
            .eq('id', response.user!.id);
      } else {
        throw Exception('Giriş başarısız: Kullanıcı bilgileri bulunamadı');
      }
    } on AuthException catch (e) {
      debugPrint('AuthProvider: Supabase hatası: ${e.message}');
      
      String errorMessage;
      if (e.message.contains('user-not-found')) {
        errorMessage = 'Bu email adresi ile kayıtlı kullanıcı bulunamadı';
      } else if (e.message.contains('wrong-password')) {
        errorMessage = 'Hatalı şifre';
      } else if (e.message.contains('invalid-email')) {
        errorMessage = 'Geçersiz email adresi';
      } else if (e.message.contains('user-disabled')) {
        errorMessage = 'Bu hesap devre dışı bırakılmış';
      } else {
        errorMessage = 'Giriş yapılırken bir hata oluştu: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('AuthProvider: Beklenmeyen hata: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phoneNumber,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        try {
          // First check if user already exists
          final existingUser = await _supabase
              .from(AppConstants.usersTable)
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (existingUser == null) {
            // Create new user record
            final newUser = await _supabase.from(AppConstants.usersTable)
                .insert({
                  'id': response.user!.id,
                  'name': name,
                  'email': email,
                  'phone': phoneNumber,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .select()
                .single();
                
            _user = app.User.fromMap(newUser);
            _isAuthenticated = true;
          } else {
            _user = app.User.fromMap(existingUser);
            _isAuthenticated = true;
          }
        } catch (e) {
          debugPrint('Error creating/fetching user record: $e');
          if (e.toString().contains('violates row-level security policy')) {
            throw Exception('Güvenlik politikası nedeniyle işlem reddedildi. Lütfen yönetici ile iletişime geçin.');
          } else if (e.toString().contains('duplicate key value')) {
            // Kullanıcı zaten varsa, mevcut kullanıcıyı getir
            try {
              final existingUser = await _supabase
                  .from(AppConstants.usersTable)
                  .select()
                  .eq('id', response.user!.id)
                  .single();
              _user = app.User.fromMap(existingUser);
              _isAuthenticated = true;
            } catch (fetchError) {
              throw Exception('Kullanıcı kaydı bulunamadı. Lütfen tekrar deneyin.');
            }
          } else {
            throw Exception('Kullanıcı kaydı oluşturulurken bir hata oluştu: $e');
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.toString().contains('weak-password')) {
        throw Exception('Şifre çok zayıf');
      } else if (e.toString().contains('email-already-in-use')) {
        throw Exception('Bu e-posta adresi zaten kullanımda');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Geçersiz e-posta adresi');
      } else {
        throw Exception('Kayıt olurken bir hata oluştu: $e');
      }
    }
  }

  Future<void> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _supabase.auth.signInAnonymously();
      
      await _supabase.from(AppConstants.usersTable).insert({
        'id': userCredential.user!.id,
        'is_anonymous': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('حدث خطأ أثناء تسجيل الدخول: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('AuthProvider: Password reset email sent successfully');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _handleAuthError(e);
    }
  }

  Exception _handleAuthError(dynamic error) {
    if (error is AuthException) {
      return Exception(error.message);
    }
    return Exception('Beklenmeyen bir hata oluştu: $error');
  }
} 