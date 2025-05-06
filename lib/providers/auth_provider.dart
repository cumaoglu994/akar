import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../utils/navigation_helper.dart';
import '../screens/home/home_screen.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    _user = _auth.currentUser;
    _isAuthenticated = _user != null;
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  Future<void> register(String email, String password, String name, String phone, String address) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      await _firestore.collection(AppConstants.usersCollection).doc(userCredential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == 'weak-password') {
        throw Exception('كلمة المرور ضعيفة جداً');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('البريد الإلكتروني مستخدم بالفعل');
      } else if (e.code == 'invalid-email') {
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

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == 'user-not-found') {
        throw Exception('لم يتم العثور على المستخدم');
      } else if (e.code == 'wrong-password') {
        throw Exception('كلمة المرور غير صحيحة');
      } else if (e.code == 'invalid-email') {
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

      await _auth.signOut();

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
      
      // Eski yöntemle giriş yap
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      final authResult = await _auth.signInWithCredential(credential);

      if (authResult.user != null) {
        debugPrint('AuthProvider: Giriş başarılı - Kullanıcı ID: ${authResult.user!.uid}');
        
        // Kullanıcı bilgilerini güncelle
        _user = authResult.user;
        _isAuthenticated = true;
        notifyListeners();

        // Firestore'da son giriş zamanını güncelle
        await _firestore.collection(AppConstants.usersCollection)
            .doc(authResult.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Giriş başarısız: Kullanıcı bilgileri bulunamadı');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthProvider: Firebase hatası: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu email adresi ile kayıtlı kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          errorMessage = 'Hatalı şifre';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi';
          break;
        case 'user-disabled':
          errorMessage = 'Bu hesap devre dışı bırakılmış';
          break;
        default:
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection(AppConstants.usersCollection).doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInAnonymously();
      
      // Create a basic user document in Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(userCredential.user!.uid).set({
        'isAnonymous': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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
      debugPrint('AuthProvider: Attempting to reset password for email: $email');
      _isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('AuthProvider: Password reset email sent successfully');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Password reset error: $e');
      debugPrint('AuthProvider: Error type: ${e.runtimeType}');
      debugPrint('AuthProvider: Error stack trace: ${StackTrace.current}');
      
      _isLoading = false;
      notifyListeners();
      if (e.toString().contains('user-not-found')) {
        throw Exception('البريد الإلكتروني غير مسجل');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('البريد الإلكتروني غير صالح');
      } else {
        throw Exception('حدث خطأ أثناء إعادة تعيين كلمة المرور: $e');
      }
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'البريد الإلكتروني غير مسجل';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة';
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح';
        default:
          return error.message ?? 'حدث خطأ غير متوقع';
      }
    }
    return error.toString();
  }
} 