import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithFacebook() async {
    try {
      // Trigger the Facebook login process
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Get the access token
        final AccessToken? accessToken = result.accessToken;

        if (accessToken != null) {
          // Create a credential for Firebase authentication
          final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.token);

          // Sign in to Firebase with the credential
          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          return userCredential.user;
        }
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception('Facebook login was cancelled by the user.');
      } else {
        throw Exception('Facebook login failed: ${result.message}');
      }
    } catch (e) {
      throw Exception('Error during Facebook login: $e');
    }
    return null;
  }

  Future<void> signOutFacebook() async {
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}
