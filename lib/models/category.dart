class AppCategory {
  final String nombre;
  final String iconKey;

  const AppCategory({required this.nombre, required this.iconKey});

  Map<String, dynamic> toMap() => {'nombre': nombre, 'icono': iconKey};

  factory AppCategory.fromMap(Map<String, dynamic> map) => AppCategory(
        nombre: map['nombre'] as String,
        iconKey: (map['icono'] as String?) ?? 'custom',
      );

  /// Categorías base de gasto, predefinidas en el cliente (no viven en
  /// Firestore) — cada fondo puede sumarle las suyas propias.
  static const gastoBase = [
    AppCategory(nombre: 'Desayuno', iconKey: 'desayuno'),
    AppCategory(nombre: 'Almuerzo', iconKey: 'almuerzo'),
    AppCategory(nombre: 'Merienda', iconKey: 'merienda'),
    AppCategory(nombre: 'Cena', iconKey: 'cena'),
    AppCategory(nombre: 'Compras', iconKey: 'compras'),
  ];

  /// Categorías base de ingreso (solo aplican en "Mi fondo" personal).
  static const ingresoBase = [
    AppCategory(nombre: 'Sueldo extra', iconKey: 'sueldo_extra'),
    AppCategory(nombre: 'Venta', iconKey: 'venta'),
    AppCategory(nombre: 'Freelance', iconKey: 'freelance'),
    AppCategory(nombre: 'Reintegro', iconKey: 'reintegro'),
  ];
}
