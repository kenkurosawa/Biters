import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/app_transaction.dart';
import '../models/category.dart';
import '../models/fund.dart';

class FundService {
  FundService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<AppUser> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().where((d) => d.exists).map(AppUser.fromDoc);
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  Future<void> updateUserProfile(String uid, {String? nombre, String? fotoUrl}) {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (fotoUrl != null) data['fotoUrl'] = fotoUrl;
    if (data.isEmpty) return Future.value();
    return _db.collection('users').doc(uid).update(data);
  }

  Future<void> updateTheme(String uid, AppThemeMode mode) {
    return _db.collection('users').doc(uid).update({'tema': AppUser.temaToString(mode)});
  }

  Stream<Fund?> streamFund(String? fundId) {
    if (fundId == null) return Stream.value(null);
    return _db
        .collection('funds')
        .doc(fundId)
        .snapshots()
        .map((d) => d.exists ? Fund.fromDoc(d) : null);
  }

  // ---------------- Transacciones ----------------

  CollectionReference<Map<String, dynamic>> _transactions(String fundId) =>
      _db.collection('funds').doc(fundId).collection('transactions');

  Stream<List<AppTransaction>> streamTransactions(String fundId, {String? mesReferencia}) {
    Query<Map<String, dynamic>> query = _transactions(fundId);
    if (mesReferencia != null) {
      query = query.where('mesReferencia', isEqualTo: mesReferencia);
    }
    query = query.orderBy('fecha', descending: true);
    return query.snapshots().map((snap) => snap.docs.map(AppTransaction.fromDoc).toList());
  }

  Future<void> addTransaction(String fundId, AppTransaction tx) {
    return _transactions(fundId).add(tx.toCreateMap());
  }

  Future<void> updateTransaction(String fundId, AppTransaction tx) {
    return _transactions(fundId).doc(tx.id).update(tx.toUpdateMap());
  }

  Future<void> deleteTransaction(String fundId, String transactionId) {
    return _transactions(fundId).doc(transactionId).delete();
  }

  // ---------------- Categorías ----------------

  DocumentReference<Map<String, dynamic>> _categoriesDoc(String fundId) =>
      _db.collection('funds').doc(fundId).collection('categories').doc('config');

  Stream<({List<AppCategory> gasto, List<AppCategory> ingreso})> streamCategories(String fundId) {
    return _categoriesDoc(fundId).snapshots().map((doc) {
      final data = doc.data();
      final gastoRaw = (data?['gastoCategorias'] as List?) ?? [];
      final ingresoRaw = (data?['ingresoCategorias'] as List?) ?? [];
      return (
        gasto: gastoRaw.map((e) => AppCategory.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
        ingreso:
            ingresoRaw.map((e) => AppCategory.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
      );
    });
  }

  Future<void> addCustomCategory(String fundId, {required bool esIngreso, required String nombre}) {
    final field = esIngreso ? 'ingresoCategorias' : 'gastoCategorias';
    final categoria = AppCategory(nombre: nombre, iconKey: 'custom');
    return _categoriesDoc(fundId).set({
      field: FieldValue.arrayUnion([categoria.toMap()]),
    }, SetOptions(merge: true));
  }
}
