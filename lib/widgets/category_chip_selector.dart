import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/category_icons.dart';

/// Fila de chips de categoría con un chip final "+ Nueva" para crear una
/// categoría al vuelo (docs/Biters_Diseno_App.pdf, pantalla 6).
class CategoryChipSelector extends StatelessWidget {
  const CategoryChipSelector({
    super.key,
    required this.categorias,
    required this.seleccionada,
    required this.onSelect,
    required this.onNueva,
  });

  final List<AppCategory> categorias;
  final String? seleccionada;
  final ValueChanged<String> onSelect;
  final VoidCallback onNueva;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cat in categorias)
          ChoiceChip(
            label: Text(cat.nombre),
            avatar: Icon(categoryIconFor(cat.iconKey), size: 18),
            selected: seleccionada == cat.nombre,
            onSelected: (_) => onSelect(cat.nombre),
            selectedColor: theme.colorScheme.primary,
            labelStyle: TextStyle(
              color: seleccionada == cat.nombre ? Colors.white : theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(
              color: seleccionada == cat.nombre ? Colors.white : theme.colorScheme.primary,
            ),
            backgroundColor: theme.cardColor,
            shape: StadiumBorder(side: BorderSide(color: theme.dividerColor)),
          ),
        ActionChip(
          label: const Text('+ Nueva'),
          onPressed: onNueva,
          backgroundColor: Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(color: theme.dividerColor, style: BorderStyle.solid),
          ),
        ),
      ],
    );
  }
}
