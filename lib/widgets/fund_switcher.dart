import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';

/// Selector compacto de fondo: dos íconos redondos (🤝 Nosotros / 👤 Mi
/// fondo). El activo tiene el borde resaltado en su color; el inactivo
/// queda atenuado. Ver docs/Biters_Diseno_App.pdf, pantalla 3.
class FundSwitcher extends StatelessWidget {
  const FundSwitcher({super.key, required this.selection, required this.onChanged});

  final FundSelection selection;
  final ValueChanged<FundSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SwitcherIcon(
          icon: Icons.handshake_rounded,
          color: BitersColors.fundoNosotros,
          selected: selection == FundSelection.nosotros,
          tooltip: 'Couple',
          onTap: () => onChanged(FundSelection.nosotros),
        ),
        const SizedBox(width: 8),
        _SwitcherIcon(
          icon: Icons.person_rounded,
          color: BitersColors.fundoPersonal,
          selected: selection == FundSelection.personal,
          tooltip: 'Mi fondo',
          onTap: () => onChanged(FundSelection.personal),
        ),
      ],
    );
  }
}

class _SwitcherIcon extends StatelessWidget {
  const _SwitcherIcon({
    required this.icon,
    required this.color,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color.withValues(alpha: 0.15) : theme.cardColor,
            border: Border.all(
              color: selected ? color : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: selected ? color : theme.disabledColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}
