import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:guardianroute/core/services/app_logger.dart';
import 'package:guardianroute/features/authentication/domain/app_user.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  AppUser? get currentUser => _mapUser(_auth.currentUser);

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  Future<AppUser> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Anonymous sign-in returned no user.');
    }
    await _ensureUserProfile();
    await _logLogin('anonymous');
    return _mapUser(user)!;
  }

  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Google sign-in returned no user.');
    }
    await _ensureUserProfile();
    await _logLogin('google');
    return _mapUser(user)!;
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> _logLogin(String method) async {
    try {
      await FirebaseAnalytics.instance.logLogin(loginMethod: method);
      await FirebaseAnalytics.instance.logEvent(name: 'login_completed');
    } catch (_) {}
  }

  Future<void> _ensureUserProfile() async {
    try {
      await _functions.httpsCallable('ensureUserProfile').call();
    } catch (_) {
      try {
        final user = _auth.currentUser;
        if (user == null) return;
        final ref = _firestore.collection('users').doc(user.uid);
        final snap = await ref.get();
        if (!snap.exists) {
          await ref.set({
            'displayName': user.displayName ?? user.email ?? 'Rider',
            'createdAt': FieldValue.serverTimestamp(),
            'lastActiveAt': FieldValue.serverTimestamp(),
          });
        } else {
          await ref.update({
            'lastActiveAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e, st) {
        appLogger.w('Fallback user profile write failed: $e\n$st');
      }
    }
  }
}
