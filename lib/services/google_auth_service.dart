import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// SOLO se usa en Android/iOS
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // WEB
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      }

      // ANDROID / IOS
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }
}
