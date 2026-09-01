import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_transaction.dart';
import '../../services/fund_service.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';
import '../../widgets/fund_gate.dart';
import '../../widgets/fund_switcher.dart';
import '../../widgets/transaction_tile.dart';

/// Pantalla 11 del PDF: historial mensual con selector de mes/año.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _mesSeleccionado = DateTime(DateTime.now().year, DateTime.now().month);

  List<DateTime> get _ultimosMeses =>
      List.generate(6, (i) => DateTime(DateTime.now().year, DateTime.now().month - i));

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final fundId = appState.activeFundId;
    final mesReferencia = AppTransaction.mesReferenciaFor(_mesSeleccionado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FundSwitcher(selection: appState.selection, onChanged: appState.setSelection),
          ),
        ],
      ),
      body: FundGate(
        fundId: fundId,
        emptyState: (_) => const Center(child: Text('Todavía no armaste tu fondo compartido "Couple".')),
        builder: (_) => SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final mes in _ultimosMeses.reversed)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(DateFormat('MMM yyyy', 'es').format(mes)),
                              selected: mes.year == _mesSeleccionado.year && mes.month == _mesSeleccionado.month,
                              onSelected: (_) => setState(() => _mesSeleccionado = mes),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<List<AppTransaction>>(
                      stream: context.read<FundService>().streamTransactions(fundId!, mesReferencia: mesReferencia),
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
                        final txs = snapshot.data!;
                        double depositado = 0, gastado = 0;
                        for (final t in txs) {
                          if (t.tipo == TransactionType.gasto) {
                            gastado += t.monto;
                          } else {
                            depositado += t.monto;
                          }
                        }

                        final grupos = <String, List<AppTransaction>>{};
                        for (final t in txs) {
                          final key = DateFormat("EEEE, d 'de' MMMM", 'es').format(t.fecha);
                          grupos.putIfAbsent(key, () => []).add(t);
                        }

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            Row(
                              children: [
                                Expanded(child: _ResumenCard(label: 'DEPOSITADO', valor: depositado)),
                                const SizedBox(width: 8),
                                Expanded(child: _ResumenCard(label: 'GASTADO', valor: gastado)),
                                const SizedBox(width: 8),
                                Expanded(child: _ResumenCard(label: 'SALDO FINAL', valor: depositado - gastado)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (grupos.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(child: Text('Sin movimientos en este mes.')),
                              ),
                            for (final entry in grupos.entries) ...[
                              Text(entry.key.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                              for (final tx in entry.value)
                                TransactionTile(
                                  tx: tx,
                                  onTap: () => context.push('/transaccion/$fundId/${tx.id}'),
                                ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 80),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.label, required this.valor});
  final String label;
  final double valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(Currency.format(valor), style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
