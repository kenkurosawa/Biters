import 'package:flutter/material.dart';

/// Mapea la clave de ícono guardada en Firestore (`iconKey`) a un ícono
/// vectorial de Material Symbols, en reemplazo de los emojis que el PDF de
/// diseño usa solo como referencia (ver docs/Biters_Diseno_App.pdf, página 2:
/// "En la app final deben reemplazarse por íconos vectoriales propios").
IconData categoryIconFor(String key) {
  switch (key) {
    case 'desayuno':
      return Icons.free_breakfast_rounded;
    case 'almuerzo':
      return Icons.lunch_dining_rounded;
    case 'merienda':
      return Icons.coffee_rounded;
    case 'cena':
      return Icons.restaurant_rounded;
    case 'compras':
      return Icons.shopping_bag_rounded;
    case 'sueldo_extra':
      return Icons.work_rounded;
    case 'venta':
      return Icons.sell_rounded;
    case 'freelance':
      return Icons.laptop_mac_rounded;
    case 'reintegro':
      return Icons.replay_circle_filled_rounded;
    case 'deposito':
      return Icons.savings_rounded;
    case 'alquiler':
      return Icons.home_rounded;
    case 'combustible':
      return Icons.local_gas_station_rounded;
    case 'supermercado':
      return Icons.shopping_cart_rounded;
    case 'servicios':
      return Icons.receipt_long_rounded;
    default:
      return Icons.label_rounded;
  }
}
