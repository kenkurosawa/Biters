import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/fund.dart';
import '../services/fund_service.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';

/// Shell compartido con la barra inferior (Inicio / Historial / Stats /
/// Perfil) y el botón '+' flotante de Inicio (docs/Biters_Diseno_App.pdf,
/// pantalla 3). Cada pestaña conserva su estado (StatefulShellRoute).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _abrirNuevoMovimiento(BuildContext context) {
    final isPersonal = context.read<AppState>().isPersonalActive;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_circle_outline_rounded),
                title: const Text('Nuevo gasto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/gasto');
                },
              ),
              if (isPersonal)
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded),
                  title: const Text('Nuevo ingreso'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/ingreso');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Nuevo depósito'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/deposito');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final fundId = appState.activeFundId;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      // Solo en Inicio, y solo si el fondo activo REALMENTE existe (no
      // alcanza con que fondoCompartidoId esté reservado en el perfil: el
      // documento del fondo recién se crea cuando la pareja canjea el
      // código — antes de eso no tiene sentido ofrecer cargar un gasto ahí).
      floatingActionButton: (navigationShell.currentIndex == 0 && fundId != null)
          ? StreamBuilder<Fund?>(
              stream: context.read<FundService>().streamFund(fundId),
              builder: (context, snapshot) {
                if (snapshot.data == null) return const SizedBox.shrink();
                return FloatingActionButton(
                  shape: const CircleBorder(),
                  backgroundColor: esOscuro ? BitersColors.coral : BitersColors.ink,
                  foregroundColor: BitersColors.cream,
                  onPressed: () => _abrirNuevoMovimiento(context),
                  child: const Icon(Icons.add),
                );
              },
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}
