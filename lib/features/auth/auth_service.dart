import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around [FirebaseAuth] and [GoogleSignIn].
///
/// Every method throws [FirebaseAuthException] on failure so callers can
/// display `e.message` in a SnackBar without knowing Firebase internals.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Email / Password ────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    // Opens the native Google account picker
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      // User cancelled the picker — treat as a cancellation, not an error
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google Sign-In was cancelled.',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    await _auth.signInWithCredential(credential);
  }

  // ── Sign Out ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // Sign out of Google first (clears the cached Google account so the
    // picker appears again next time, rather than auto-selecting).
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
