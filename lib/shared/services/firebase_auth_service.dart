import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithFacebook(String accessToken) async {
    try {
      final OAuthCredential credential = FacebookAuthProvider.credential(accessToken);
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userRef = _firestore.collection("users").doc(firebaseUser.uid);
        DocumentSnapshot doc = await userRef.get();

        if (!doc.exists) {
          await userRef.set({
            "uid": firebaseUser.uid,
            "userName": firebaseUser.displayName,
            "email": firebaseUser.email,
            "photoUrl": firebaseUser.photoURL,
            "createdAt": FieldValue.serverTimestamp(),
          });
        } else {
          await userRef.update({
            "userName": firebaseUser.displayName,
            "photoUrl": firebaseUser.photoURL,
          });
        }
      }
    } catch (e) {
      throw Exception("Firebase Sign-In Error: $e");
    }
  }
}
