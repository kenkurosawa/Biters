import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fund.dart';
import '../services/fund_service.dart';

/// Envuelve contenido que necesita un fondo compartido REAL. `fondoCompartidoId`
/// en el perfil solo significa "reservado" (se asigna la primera vez que se
/// genera un código de invitación) — el documento del fondo recién existe
/// cuando alguien canjea el código. Este widget chequea la existencia real
/// antes de mostrar contenido, para no intentar leer/escribir en un fondo
/// que todavía no existe.
class FundGate extends StatelessWidget {
  const FundGate({
    super.key,
    required this.fundId,
    required this.builder,
    required this.emptyState,
  });

  final String? fundId;
  final Widget Function(BuildContext context, Fund fund) builder;
  final WidgetBuilder emptyState;

  @override
  Widget build(BuildContext context) {
    final id = fundId;
    if (id == null) return emptyState(context);

    return StreamBuilder<Fund?>(
      stream: context.read<FundService>().streamFund(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final fund = snapshot.data;
        if (fund == null) return emptyState(context);
        return builder(context, fund);
      },
    );
  }
}
