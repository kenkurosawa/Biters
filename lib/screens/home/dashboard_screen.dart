import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_transaction.dart';
import '../../services/fund_service.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/fund_switcher.dart';
import '../../widgets/transaction_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final appUser = appState.appUser;
    if (appUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final esNosotros = appState.selection == FundSelection.nosotros;
    final fundId = appState.activeFundId;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, ${appUser.nombre.split(' ').first} 👋',
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text(
                          '${_mesActual()} · ${esNosotros ? 'Nosotros' : 'Solo vos lo ves'}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  FundSwitcher(
                    selection: appState.selection,
                    onChanged: appState.setSelection,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: fundId == null
                    ? _SinFondoCompartido(onInvitar: () => context.push('/invitar'))
                    : _FundContent(fundId: fundId, esNosotros: esNosotros),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _mesActual() {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final now = DateTime.now();
    return '${meses[now.month - 1]} ${now.year}';
  }
}

class _FundContent extends StatelessWidget {
  const _FundContent({required this.fundId, required this.esNosotros});

  final String fundId;
  final bool esNosotros;

  @override
  Widget build(BuildContext context) {
    final fundService = context.read<FundService>();
    final mesReferencia = AppTransaction.mesReferenciaFor(DateTime.now());

    return StreamBuilder<List<AppTransaction>>(
      stream: fundService.streamTransactions(fundId, mesReferencia: mesReferencia),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final txs = snapshot.data!;
        double depositos = 0, ingresos = 0, gastos = 0;
        for (final t in txs) {
          switch (t.tipo) {
            case TransactionType.deposito:
              depositos += t.monto;
            case TransactionType.ingreso:
              ingresos += t.monto;
            case TransactionType.gasto:
              gastos += t.monto;
          }
        }
        final totalPositivo = depositos + ingresos;
        final saldo = totalPositivo - gastos;
        final recientes = txs.take(6).toList();

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              BalanceCard(
                saldoDisponible: saldo,
                totalPositivo: totalPositivo,
                totalGastado: gastos,
                labelPositivo: esNosotros ? 'Depositado' : 'Ingresos',
                baseColor: esNosotros ? BitersColors.coral : BitersColors.teal,
              ),
              const SizedBox(height: 24),
              Text('Movimientos recientes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (recientes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Todavía no hay movimientos este mes.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                for (final tx in recientes)
                  TransactionTile(
                    tx: tx,
                    onTap: () => context.push('/transaccion/$fundId/${tx.id}'),
                  ),
              const SizedBox(height: 96),
            ],
          ),
        );
      },
    );
  }
}

class _SinFondoCompartido extends StatelessWidget {
  const _SinFondoCompartido({required this.onInvitar});

  final VoidCallback onInvitar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_rounded, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Todavía no armaste tu fondo\ncompartido', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Invitá a tu pareja con un código de 6 dígitos para empezar a compartir "Nosotros".',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onInvitar, child: const Text('Invitar a tu pareja')),
        ],
      ),
    );
  }
}
