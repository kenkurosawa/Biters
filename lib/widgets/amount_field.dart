import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Campo grande de monto ("Gs. 0") para Nuevo gasto/ingreso/depósito.
/// Siempre fondo blanco con texto oscuro, a propósito: independiente del
/// tema claro/oscuro, para que el número sea legible sin depender de cómo
/// resuelva el tema (evita el bug de dígitos en teal oscuro sobre fondo
/// oscuro).
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
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
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
