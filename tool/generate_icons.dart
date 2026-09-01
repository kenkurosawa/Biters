// Genera los PNG del ícono de la app (legacy + adaptive foreground) a
// partir de la misma geometría del logo en lib/widgets/biters_logo.dart.
// Uso: dart run tool/generate_icons.dart
// Es un script de un solo uso; el paquete `image` es un dev_dependency
// temporal (se puede sacar de pubspec.yaml después de correr esto).
import 'dart:io';
import 'package:image/image.dart' as img;

const coral = 0xFFFF5A36;
const cream = 0xFFFFF6ED;

img.Color colorFromArgbHex(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return img.ColorRgba8(r, g, b, a);
}

void drawCircle(img.Image image, double cx, double cy, double r, img.Color color) {
  img.fillCircle(image, x: cx.round(), y: cy.round(), radius: r.round(), color: color);
}

// Ícono legacy (mipmap-*/ic_launcher.png): fondo crema cuadrado, círculo
// coral con el "mordisco" recortado, mismas proporciones que BitersLogo.
img.Image legacyIcon(int size) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  img.fill(image, color: colorFromArgbHex(0xFF000000 | cream));

  final margin = size * 0.06;
  final logoSize = size - margin * 2;
  final logoCenter = size / 2;
  final radius = logoSize / 2;

  drawCircle(image, logoCenter, logoCenter, radius, colorFromArgbHex(0xFF000000 | coral));

  final biteCx = margin + logoSize * 0.80;
  final biteCy = margin + logoSize * 0.17;
  final biteR = logoSize * 0.31;
  drawCircle(image, biteCx, biteCy, biteR, colorFromArgbHex(0xFF000000 | cream));

  return image;
}

// Foreground del adaptive icon: fondo TRANSPARENTE (el color de fondo
// coral ya lo pone android:drawable="@color/ic_launcher_background" en
// ic_launcher.xml), con el "mordisco" recortado en color crema. El resto
// del canvas queda transparente para que se vea el coral del background
// layer. android:inset="16%" en el XML ya se encarga del margen de
// seguridad del ícono adaptable.
img.Image adaptiveForeground(int size) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  img.fill(image, color: colorFromArgbHex(0x00000000));

  final biteCx = size * 0.80;
  final biteCy = size * 0.17;
  final biteR = size * 0.31;
  drawCircle(image, biteCx, biteCy, biteR, colorFromArgbHex(0xFF000000 | cream));

  return image;
}

void writePng(img.Image image, String path) {
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path (${image.width}x${image.height})');
}

void main() {
  const legacySizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  const foregroundSizes = {
    'drawable-mdpi': 108,
    'drawable-hdpi': 162,
    'drawable-xhdpi': 216,
    'drawable-xxhdpi': 324,
    'drawable-xxxhdpi': 432,
  };

  const resDir = 'android/app/src/main/res';

  legacySizes.forEach((dir, size) {
    writePng(legacyIcon(size), '$resDir/$dir/ic_launcher.png');
  });

  foregroundSizes.forEach((dir, size) {
    writePng(adaptiveForeground(size), '$resDir/$dir/ic_launcher_foreground.png');
  });

  // Ícono de referencia grande, útil para Play Console / stores (512x512).
  Directory('assets/icon').createSync(recursive: true);
  writePng(legacyIcon(512), 'assets/icon/icon.png');
}
