import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// El logo de Biters: círculo coral con un "mordisco" — un círculo más
/// chico, del color del fondo, superpuesto arriba a la derecha (ver
/// docs/Biters_Diseno_App.pdf, página 2). El color del "mordisco" sigue el
/// fondo real detrás del logo (recibido por parámetro) para que se vea
/// bien tanto en modo claro como oscuro.
class BitersLogo extends StatelessWidget {
  const BitersLogo({super.key, this.size = 72, this.backgroundColor});

  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BiteLogoPainter(bg)),
    );
  }
}

class _BiteLogoPainter extends CustomPainter {
  _BiteLogoPainter(this.backgroundColor);

  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = BitersColors.coral;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, paint);

    final bitePaint = Paint()..color = backgroundColor;
    final biteCenter = Offset(size.width * 0.80, size.height * 0.17);
    canvas.drawCircle(biteCenter, size.width * 0.31, bitePaint);
  }

  @override
  bool shouldRepaint(covariant _BiteLogoPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor;
}
