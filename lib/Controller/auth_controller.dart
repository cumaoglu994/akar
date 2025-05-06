import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AuthController {
  static String? hizmetTuru;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImageToStorage(Uint8List? image) async {
    Reference ref =
        _storage.ref().child('profilePics').child(_auth.currentUser!.uid);
    UploadTask uploadTask = ref.putData(image!);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  pickProfileImage(ImageSource fotoSource) async {
    final ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: fotoSource);
    if (file != null) {
      return await file.readAsBytes();
    } else {
      // print('no image selected');
    }
  }

  Future<String> signUpUsers(String email, String name, String phoneNumber,
      String password, Uint8List? image) async {
    String res = 'حدث خطأ ما';
    try {
      if (email.isNotEmpty &&
          name.isNotEmpty &&
          phoneNumber.isNotEmpty &&
          password.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);

        String profileImageUrl = '';
        if (image != null) {
          profileImageUrl = await uploadProfileImageToStorage(image);
        }

        await _firestore.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'name': name,
          'phoneNumber': phoneNumber,
          'userId': cred.user!.uid,
          'profileImage': profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        res = 'success';
      } else {
        res = 'يرجى ملء جميع الحقول';
      }
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        res = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (e.toString().contains('weak-password')) {
        res = 'كلمة المرور ضعيفة جداً';
      } else {
        res = e.toString();
      }
    }
    return res;
  }

  Future<String> loginUsers(String email, String password) async {
    String res = 'حدث خطأ ما';
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        
        // Giriş zamanını güncelle
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        res = 'success';
      } else {
        res = 'يرجى ملء جميع الحقول';
      }
    } catch (e) {
      if (e.toString().contains('user-not-found')) {
        res = 'لم يتم العثور على المستخدم';
      } else if (e.toString().contains('wrong-password')) {
        res = 'كلمة المرور غير صحيحة';
      } else {
        res = e.toString();
      }
    }
    return res;
  }
}
