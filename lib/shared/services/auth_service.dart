import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:js' as js;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '1045583437831-435og125lq6kn1ifiq5l8j4ni3fjndi2.apps.googleusercontent.com',
  );

  // Đăng nhập bằng email & password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } catch (e) {
      print('Login error: $e');
      throw e;
    }
  }

  Future<User?> registerWithEmail(String email, String password,
      String userName, String phoneNumber) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'userName': userName.trim(),
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print('Registration error: $e');
      throw e;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user == null) return null;

      final GoogleSignInAuthentication googleAuth = await user.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      throw e;
    }
  }

  Future<void> saveUserData(User user) async {
    final userRef =
        FirebaseFirestore.instance.collection("users").doc(user.uid);
    DocumentSnapshot doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        "uid": user.uid,
        "userName": user.displayName,
        "email": user.email,
        "photoUrl": user.photoURL,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.update({
        "userName": user.displayName,
        "photoUrl": user.photoURL,
      });
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('Please fill in all fields');
    }

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user');
      }

      // Xác thực lại bằng email & mật khẩu cũ
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Cập nhật mật khẩu mới
      await user.updatePassword(newPassword);

      // Cập nhật Firestore nếu cần
      await _firestore.collection('users').doc(user.uid).update({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      var fb = js.context['FB'];
  
      // Đăng xuất khỏi Facebook nếu SDK có sẵn
      if (fb != null && fb.callMethod != null) {
        print("Logging out from Facebook...");
        fb.callMethod('logout', [
          js.allowInterop((response) {
            print("User logged out from Facebook.");
          })
        ]);
      }

      // Đăng xuất khỏi Firebase
      await _auth.signOut();
      print('User logged out successfully from Firebase');
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }
}
