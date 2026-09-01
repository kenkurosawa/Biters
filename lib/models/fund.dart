import 'package:cloud_firestore/cloud_firestore.dart';

enum FundType { personal, compartido }

class Fund {
  final String id;
  final FundType tipo;
  final List<String> members;
  final DateTime fechaCreacion;
  final String? creadoConCodigo;

  /// Mapa de uid a nombre, para mostrar "compartiendo con..." sin tener que
  /// leer el documento de otro usuario (users/{uid} es privado). Se llena
  /// al canjear el invite, con el nombre que cada quien tenía en ese
  /// momento (ver InviteService).
  final Map<String, String> memberNames;

  const Fund({
    required this.id,
    required this.tipo,
    required this.members,
    required this.fechaCreacion,
    this.creadoConCodigo,
    this.memberNames = const {},
  });

  factory Fund.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Fund(
      id: doc.id,
      tipo: (data['tipo'] as String) == 'compartido' ? FundType.compartido : FundType.personal,
      members: List<String>.from(data['members'] as List? ?? []),
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creadoConCodigo: data['creadoConCodigo'] as String?,
      memberNames: Map<String, String>.from(data['memberNames'] as Map? ?? {}),
    );
  }

  /// El nombre del otro miembro (solo tiene sentido en un fondo compartido).
  String? partnerName(String myUid) {
    for (final entry in memberNames.entries) {
      if (entry.key != myUid) return entry.value;
    }
    return null;
  }
}
