import 'package:cloud_firestore/cloud_firestore.dart';

enum AppThemeMode { claro, oscuro, auto }

class AppUser {
  final String uid;
  final String nombre;
  final String email;
  final String? fotoUrl;
  final DateTime fechaCreacion;
  final String fondoPersonalId;
  final String? fondoCompartidoId;
  final AppThemeMode tema;

  const AppUser({
    required this.uid,
    required this.nombre,
    required this.email,
    this.fotoUrl,
    required this.fechaCreacion,
    required this.fondoPersonalId,
    this.fondoCompartidoId,
    this.tema = AppThemeMode.auto,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      nombre: data['nombre'] as String? ?? '',
      email: data['email'] as String? ?? '',
      fotoUrl: data['fotoUrl'] as String?,
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fondoPersonalId: data['fondoPersonalId'] as String,
      fondoCompartidoId: data['fondoCompartidoId'] as String?,
      tema: _temaFromString(data['tema'] as String?),
    );
  }

  static AppThemeMode _temaFromString(String? value) {
    switch (value) {
      case 'claro':
        return AppThemeMode.claro;
      case 'oscuro':
        return AppThemeMode.oscuro;
      default:
        return AppThemeMode.auto;
    }
  }

  static String temaToString(AppThemeMode mode) => switch (mode) {
        AppThemeMode.claro => 'claro',
        AppThemeMode.oscuro => 'oscuro',
        AppThemeMode.auto => 'auto',
      };
}
