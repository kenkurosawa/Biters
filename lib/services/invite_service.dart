import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteFailure { notFound, used, expired, self, full }

class InviteException implements Exception {
  final InviteFailure reason;
  const InviteException(this.reason);

  String get mensaje => switch (reason) {
        InviteFailure.notFound => 'Ese código no existe. Revisá que esté bien escrito.',
        InviteFailure.used => 'Ese código ya fue usado.',
        InviteFailure.expired => 'Ese código venció. Pedile a tu pareja que genere uno nuevo.',
        InviteFailure.self => 'No podés unirte con tu propio código.',
        InviteFailure.full => 'Ese fondo ya tiene 2 personas vinculadas.',
      };
}

class GeneratedInvite {
  final String codigo;
  final DateTime expiresAt;
  const GeneratedInvite({required this.codigo, required this.expiresAt});
}

/// Flujo de invitación al fondo "Nosotros" con código de 6 dígitos, sin
/// Cloud Functions: todo se resuelve con reglas de Firestore + una
/// transacción atómica en el cliente. Ver docs/MODELO_DE_DATOS.md.
class InviteService {
  InviteService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _rng = Random.secure();

  /// Genera (o reutiliza) el código de invitación del fondo compartido del
  /// usuario. La primera vez, reserva un fondoCompartidoId en su perfil.
  Future<GeneratedInvite> generateInvite(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final userSnap = await userRef.get();
    String? fundId = userSnap.data()?['fondoCompartidoId'] as String?;

    if (fundId == null) {
      fundId = _db.collection('funds').doc().id;
      await userRef.update({'fondoCompartidoId': fundId});
    }

    // No hace falta chequear de antemano si el código ya existe: con 900.000
    // combinaciones posibles, una colisión es casi imposible, y si pasara,
    // Firestore la trata como "update" (no "create") y la regla de
    // seguridad la rechaza sola — alcanza con reintentar con otro código.
    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    var code = _randomCode();
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await _db.collection('invites').doc(code).set({
          'fundIdDestino': fundId,
          'creadoPor': uid,
          'expiresAt': Timestamp.fromDate(expiresAt),
          'used': false,
          'usedBy': null,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
        return GeneratedInvite(codigo: code, expiresAt: expiresAt);
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied' || attempt == 4) rethrow;
        code = _randomCode();
      }
    }
    throw StateError('No se pudo generar un código único.');
  }

  String _randomCode() => (100000 + _rng.nextInt(900000)).toString();

  /// Canjea un código: crea el fondo compartido (si hace falta), vincula al
  /// que se une, y marca el invite como usado. Todo atómico.
  Future<String> redeemInvite({required String codigo, required String joinerUid}) async {
    final inviteRef = _db.collection('invites').doc(codigo);

    return _db.runTransaction<String>((tx) async {
      final inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists) throw const InviteException(InviteFailure.notFound);

      final data = inviteSnap.data()!;
      final used = data['used'] as bool? ?? true;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final creadoPor = data['creadoPor'] as String;
      final fundId = data['fundIdDestino'] as String;

      if (used) throw const InviteException(InviteFailure.used);
      if (DateTime.now().isAfter(expiresAt)) throw const InviteException(InviteFailure.expired);
      if (creadoPor == joinerUid) throw const InviteException(InviteFailure.self);

      final fundRef = _db.collection('funds').doc(fundId);
      final fundSnap = await tx.get(fundRef);
      if (fundSnap.exists) {
        final members = List<String>.from(fundSnap.data()?['members'] as List? ?? []);
        if (members.length >= 2) throw const InviteException(InviteFailure.full);
      }

      final joinerRef = _db.collection('users').doc(joinerUid);

      tx.update(inviteRef, {'used': true, 'usedBy': joinerUid});
      tx.set(fundRef, {
        'tipo': 'compartido',
        'members': [creadoPor, joinerUid],
        'fechaCreacion': FieldValue.serverTimestamp(),
        'creadoConCodigo': codigo,
      });
      tx.update(joinerRef, {'fondoCompartidoId': fundId});

      return fundId;
    });
  }
}
