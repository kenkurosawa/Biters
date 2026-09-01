import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Autenticación + creación del "Mi fondo" personal al registrarse.
///
/// El fondo personal se crea en el mismo momento del registro (como indica
/// docs/Biters_Diseno_App.pdf, pantalla 2), pero el acceso a las funciones
/// principales de la app queda bloqueado por la UI (ver VerifyEmailScreen)
/// hasta que el usuario confirme su email.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signUp({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(nombre);

    final fundRef = _db.collection('funds').doc();
    final userRef = _db.collection('users').doc(user.uid);
    final batch = _db.batch();
    batch.set(fundRef, {
      'tipo': 'personal',
      'members': [user.uid],
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
    batch.set(userRef, {
      'nombre': nombre,
      'email': email,
      'fotoUrl': null,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fondoPersonalId': fundRef.id,
      'fondoCompartidoId': null,
      'tema': 'auto',
    });
    await batch.commit();

    await user.sendEmailVerification();
  }

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Refresca el estado del usuario actual (para el botón "Ya lo verifiqué").
  Future<bool> reloadAndCheckVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() => _auth.signOut();
}
