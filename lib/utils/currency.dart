import 'package:intl/intl.dart';

/// Formatea montos en guaraníes: "Gs. 1.250.000" (separador de miles, sin
/// decimales), como usa el diseño en docs/Biters_Diseno_App.pdf.
class Currency {
  Currency._();

  // NumberFormat.currency ubica el símbolo según el patrón del locale
  // (en es_PY va al final: "1.250.000 Gs."), así que formateamos el
  // número solo (con el separador de miles '.' de es_PY) y anteponemos
  // "Gs. " nosotros, para que siempre quede "Gs. 1.250.000".
  static final _format = NumberFormat.decimalPattern('es_PY')..maximumFractionDigits = 0;

  static String format(num amount) => 'Gs. ${_format.format(amount)}';

  /// Igual que [format] pero con signo +/- explícito, para listas de
  /// movimientos (+ Gs. 500.000 / - Gs. 120.000).
  static String formatSigned(num amount, {required bool positive}) {
    final sign = positive ? '+ ' : '- ';
    return '$sign${format(amount.abs())}';
  }
}
