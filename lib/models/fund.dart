import 'package:cloud_firestore/cloud_firestore.dart';

enum FundType { personal, compartido }

class Fund {
  final String id;
  final FundType tipo;
  final List<String> members;
  final DateTime fechaCreacion;
  final String? creadoConCodigo;

  const Fund({
    required this.id,
    required this.tipo,
    required this.members,
    required this.fechaCreacion,
    this.creadoConCodigo,
  });

  factory Fund.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Fund(
      id: doc.id,
      tipo: (data['tipo'] as String) == 'compartido' ? FundType.compartido : FundType.personal,
      members: List<String>.from(data['members'] as List? ?? []),
      fechaCreacion: (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creadoConCodigo: data['creadoConCodigo'] as String?,
    );
  }
}
