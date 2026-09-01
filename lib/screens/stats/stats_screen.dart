import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_transaction.dart';
import '../../services/fund_service.dart';
import '../../state/app_state.dart';
import '../../utils/category_icons.dart';
import '../../utils/currency.dart';
import '../../widgets/fund_switcher.dart';

/// Pantallas 12 y 13 del PDF: Estadísticas, vista General y Por subcategoría.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _porSubcategoria = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final fundId = appState.activeFundId;
    final mesReferencia = AppTransaction.mesReferenciaFor(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FundSwitcher(selection: appState.selection, onChanged: appState.setSelection),
          ),
        ],
      ),
      body: fundId == null
          ? const Center(child: Text('Todavía no tenés un fondo compartido.'))
          : SafeArea(
              child: StreamBuilder<List<AppTransaction>>(
                stream: context.read<FundService>().streamTransactions(fundId, mesReferencia: mesReferencia),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'No se pudo cargar. Probá de nuevo en un momento.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final gastos = snapshot.data!.where((t) => t.tipo == TransactionType.gasto).toList();
                  final totalGastado = gastos.fold(0.0, (s, t) => s + t.monto);

                  final porCategoria = <String, double>{};
                  final itemsPorCategoria = <String, Map<String, double>>{};
                  for (final g in gastos) {
                    porCategoria.update(g.categoria, (v) => v + g.monto, ifAbsent: () => g.monto);
                    final mapa = itemsPorCategoria.putIfAbsent(g.categoria, () => {});
                    for (final item in g.items) {
                      mapa.update(item.subcategoria, (v) => v + item.monto, ifAbsent: () => item.monto);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Total gastado ${Currency.format(totalGastado)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 12),
                        _ViewToggle(
                          porSubcategoria: _porSubcategoria,
                          onChanged: (v) => setState(() => _porSubcategoria = v),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: porCategoria.isEmpty
                              ? const Center(child: Text('Sin gastos este mes.'))
                              : _porSubcategoria
                                  ? _SubcategoriaView(itemsPorCategoria: itemsPorCategoria, porCategoria: porCategoria)
                                  : _GeneralView(porCategoria: porCategoria, total: totalGastado),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.porSubcategoria, required this.onChanged});
  final bool porSubcategoria;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: _Seg(icon: Icons.bar_chart_rounded, label: 'General', selected: !porSubcategoria, onTap: () => onChanged(false)),
          ),
          Expanded(
            child: _Seg(icon: Icons.search_rounded, label: 'Por subcategoría', selected: porSubcategoria, onTap: () => onChanged(true)),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.scaffoldBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? theme.colorScheme.primary : theme.disabledColor),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? theme.colorScheme.onSurface : theme.disabledColor,
            )),
          ],
        ),
      ),
    );
  }
}

class _GeneralView extends StatelessWidget {
  const _GeneralView({required this.porCategoria, required this.total});
  final Map<String, double> porCategoria;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = porCategoria.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      children: [
        for (final e in entries) ...[
          Row(
            children: [
              Icon(categoryIconFor(e.key.toLowerCase()), size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(e.key, style: theme.textTheme.titleMedium)),
              Text(
                '${Currency.format(e.value)} · ${total == 0 ? 0 : (e.value / total * 100).round()}%',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : e.value / total,
              minHeight: 8,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _SubcategoriaView extends StatelessWidget {
  const _SubcategoriaView({required this.itemsPorCategoria, required this.porCategoria});
  final Map<String, Map<String, double>> itemsPorCategoria;
  final Map<String, double> porCategoria;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categorias = porCategoria.keys.toList()
      ..sort((a, b) => porCategoria[b]!.compareTo(porCategoria[a]!));

    return ListView(
      children: [
        for (final cat in categorias) ...[
          Row(
            children: [
              Icon(categoryIconFor(cat.toLowerCase()), size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '${cat.toUpperCase()} · ${Currency.format(porCategoria[cat]!)}',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if ((itemsPorCategoria[cat] ?? {}).isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 8),
              child: Text('Sin detalle por ítems todavía.', style: theme.textTheme.labelSmall),
            )
          else
            for (final item in itemsPorCategoria[cat]!.entries)
              Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.key, style: theme.textTheme.bodyMedium),
                    Text(Currency.format(item.value), style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
