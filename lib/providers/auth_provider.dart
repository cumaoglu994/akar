import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../utils/navigation_helper.dart';
import '../screens/home/home_screen.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _supabase.auth.currentUser;
    _isAuthenticated = _user != null;
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
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
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.message.contains('weak-password')) {
        throw Exception('كلمة المرور ضعيفة جداً');
      } else if (e.message.contains('email-already-in-use')) {
        throw Exception('البريد الإلكتروني مستخدم بالفعل');
      } else if (e.message.contains('invalid-email')) {
        throw Exception('البريد الإلكتروني غير صالح');
      } else {
        throw Exception('حدث خطأ أثناء التسجيل: ${e.message}');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _isLoading = false;
      notifyListeners();
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.message.contains('user-not-found')) {
        throw Exception('لم يتم العثور على المستخدم');
      } else if (e.message.contains('wrong-password')) {
        throw Exception('كلمة المرور غير صحيحة');
      } else if (e.message.contains('invalid-email')) {
        throw Exception('البريد الإلكتروني غير صالح');
      } else {
        throw Exception('حدث خطأ أثناء تسجيل الدخول: ${e.message}');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.signOut();

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
        
        _user = response.user;
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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _supabase.from(AppConstants.usersTable).insert({
          'id': response.user!.id,
          'name': name,
          'email': email,
          'phone': phoneNumber,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw _handleAuthError(e);
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