import 'package:flutter/material.dart';

/// Paleta oficial de Biters (ver docs/Biters_Diseno_App.pdf, página 2).
class BitersColors {
  BitersColors._();

  static const coral = Color(0xFFFF5A36);
  static const coralDark = Color(0xFFD9431F);
  static const teal = Color(0xFF0F5C56);
  static const gold = Color(0xFFFFB238);
  static const cream = Color(0xFFFFF6ED);
  static const ink = Color(0xFF2A1E17);

  // Modo oscuro: charcoal cálido, nunca negro puro.
  static const charcoal900 = Color(0xFF1D1712);
  static const charcoal800 = Color(0xFF2A2119);

  static const success = Color(0xFF2F9E6B);
  static const danger = Color(0xFFD9431F);

  /// Color de marca del fondo "Nosotros".
  static const fundoNosotros = coral;

  /// Color de marca de "Mi fondo" personal.
  static const fundoPersonal = teal;
}
