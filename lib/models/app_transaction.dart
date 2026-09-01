import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { gasto, ingreso, deposito }

enum ExpenseMode { rapido, detallado }

class TransactionItem {
  final String subcategoria;
  final double monto;

  const TransactionItem({required this.subcategoria, required this.monto});

  Map<String, dynamic> toMap() => {'subcategoria': subcategoria, 'monto': monto};

  factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem(
        subcategoria: map['subcategoria'] as String,
        monto: (map['monto'] as num).toDouble(),
      );
}

class AppTransaction {
  final String id;
  final TransactionType tipo;
  final double monto;
  final String descripcion;
  final String categoria;
  final ExpenseMode? modo;
  final List<TransactionItem> items;
  final String registradoPor;
  final String registradoPorNombre;
  final String? depositante;
  final DateTime fecha;
  final String mesReferencia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppTransaction({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.categoria,
    this.modo,
    this.items = const [],
    required this.registradoPor,
    required this.registradoPorNombre,
    this.depositante,
    required this.fecha,
    required this.mesReferencia,
    this.createdAt,
    this.updatedAt,
  });

  static TransactionType _tipoFromString(String value) => switch (value) {
        'ingreso' => TransactionType.ingreso,
        'deposito' => TransactionType.deposito,
        _ => TransactionType.gasto,
      };

  static String tipoToString(TransactionType tipo) => switch (tipo) {
        TransactionType.gasto => 'gasto',
        TransactionType.ingreso => 'ingreso',
        TransactionType.deposito => 'deposito',
      };

  factory AppTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final modoStr = data['modo'] as String?;
    return AppTransaction(
      id: doc.id,
      tipo: _tipoFromString(data['tipo'] as String),
      monto: (data['monto'] as num).toDouble(),
      descripcion: data['descripcion'] as String? ?? '',
      categoria: data['categoria'] as String? ?? '',
      modo: modoStr == 'detallado'
          ? ExpenseMode.detallado
          : (modoStr == 'rapido' ? ExpenseMode.rapido : null),
      items: ((data['items'] as List?) ?? [])
          .map((e) => TransactionItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      registradoPor: data['registradoPor'] as String,
      registradoPorNombre: data['registradoPorNombre'] as String? ?? '',
      depositante: data['depositante'] as String?,
      fecha: (data['fecha'] as Timestamp).toDate(),
      mesReferencia: data['mesReferencia'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'tipo': tipoToString(tipo),
      'monto': monto,
      'descripcion': descripcion,
      'categoria': categoria,
      if (modo != null) 'modo': modo == ExpenseMode.detallado ? 'detallado' : 'rapido',
      'items': items.map((e) => e.toMap()).toList(),
      'registradoPor': registradoPor,
      'registradoPorNombre': registradoPorNombre,
      if (depositante != null) 'depositante': depositante,
      'fecha': Timestamp.fromDate(fecha),
      'mesReferencia': mesReferencia,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'monto': monto,
      'descripcion': descripcion,
      'categoria': categoria,
      if (modo != null) 'modo': modo == ExpenseMode.detallado ? 'detallado' : 'rapido',
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isGastoDetallado => tipo == TransactionType.gasto && modo == ExpenseMode.detallado;
  bool get isGastoRapidoSinItems =>
      tipo == TransactionType.gasto && modo == ExpenseMode.rapido && items.isEmpty;

  static String mesReferenciaFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
}
