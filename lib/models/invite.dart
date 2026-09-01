import 'package:cloud_firestore/cloud_firestore.dart';

class Invite {
  final String codigo;
  final String fundIdDestino;
  final String creadoPor;
  final DateTime expiresAt;
  final bool used;
  final String? usedBy;
  final DateTime fechaCreacion;

  const Invite({
    required this.codigo,
    required this.fundIdDestino,
    required this.creadoPor,
    required this.expiresAt,
    required this.used,
    this.usedBy,
    required this.fechaCreacion,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !used && !isExpired;

  factory Invite.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Invite(
      codigo: doc.id,
      fundIdDestino: data['fundIdDestino'] as String,
      creadoPor: data['creadoPor'] as String,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      used: data['used'] as bool? ?? false,
      usedBy: data['usedBy'] as String?,
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
