import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/fund_service.dart';

enum FundSelection { nosotros, personal }

/// Estado global de sesión: usuario de Firebase Auth, su documento de
/// Firestore (users/{uid}), y cuál de los dos fondos está activo en
/// pantalla. Un solo lugar para que Inicio/Historial/Estadísticas lean el
/// mismo estado y nunca mezclen datos de ambos fondos.
class AppState extends ChangeNotifier {
  AppState({required this.authService, required this.fundService}) {
    _authSub = authService.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService authService;
  final FundService fundService;

  User? firebaseUser;
  AppUser? appUser;
  bool initializing = true;
  FundSelection selection = FundSelection.nosotros;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser>? _userSub;

  void _onAuthChanged(User? user) {
    firebaseUser = user;
    _userSub?.cancel();
    _userSub = null;

    if (user == null) {
      appUser = null;
      initializing = false;
      notifyListeners();
      return;
    }

    _userSub = fundService.streamUser(user.uid).listen(
      (u) {
        appUser = u;
        initializing = false;
        notifyListeners();
      },
      onError: (_) {
        initializing = false;
        notifyListeners();
      },
    );
  }

  /// Se llama tras "Ya lo verifiqué" para reflejar `emailVerified` sin
  /// esperar al próximo evento de authStateChanges.
  void refreshFirebaseUser() {
    firebaseUser = authService.currentUser;
    notifyListeners();
  }

  void setSelection(FundSelection s) {
    if (selection == s) return;
    selection = s;
    notifyListeners();
  }

  String? get activeFundId =>
      selection == FundSelection.nosotros ? appUser?.fondoCompartidoId : appUser?.fondoPersonalId;

  bool get isPersonalActive => selection == FundSelection.personal;

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
