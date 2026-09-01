import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

/// Formatea en vivo mientras se escribe: "4500000" -> "4.500.000" (mismo
/// separador de miles que Currency.format en el resto de la app). El
/// cursor queda siempre al final, como en cualquier teclado numérico de
/// monto (no hay decimales que insertar en el medio).
class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final remaining = trimmed.length - i;
      buffer.write(trimmed[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Campo grande de monto ("Gs. 0") para Nuevo gasto/ingreso/depósito.
/// Siempre fondo blanco con texto oscuro, a propósito: independiente del
/// tema claro/oscuro, para que el número sea legible sin depender de cómo
/// resuelva el tema (evita el bug de dígitos en teal oscuro sobre fondo
/// oscuro). Formatea el monto con separador de miles a medida que se
/// escribe.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.hintText = '0',
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool autofocus;

  /// Convierte el texto formateado ("4.500.000") al número real (4500000).
  static double parse(String formattedText) {
    final digits = formattedText.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : double.parse(digits);
  }

  /// El mismo formateador de separador de miles, para usar en campos de
  /// monto más chicos que no son este widget (ej. ítems de una factura).
  static TextInputFormatter thousandsFormatter() => _ThousandsInputFormatter();

  static const _digitStyle = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontWeight: FontWeight.w700,
    fontSize: 34,
    color: BitersColors.ink,
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [_ThousandsInputFormatter()],
      cursorColor: BitersColors.coral,
      style: _digitStyle,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: BitersColors.coral, width: 2),
        ),
        prefixText: 'Gs. ',
        prefixStyle: _digitStyle,
        hintText: hintText,
        hintStyle: _digitStyle.copyWith(color: BitersColors.ink.withValues(alpha: 0.35)),
      ),
    );
  }
}
