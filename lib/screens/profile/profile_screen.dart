import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_transaction.dart';
import '../../models/app_user.dart';
import '../../models/fund.dart';
import '../../services/auth_service.dart';
import '../../services/fund_service.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';

/// Pantalla 16 del PDF: Perfil.
///
/// Sin foto de perfil por decisión de producto: Cloud Storage para Firebase
/// ahora exige el plan Blaze (pago por uso) incluso para uso dentro del
/// nivel gratuito, y se optó por quedarse 100% en Spark. El avatar se
/// muestra siempre con las iniciales del nombre.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editarNombre(BuildContext context, String actual) async {
    final ctrl = TextEditingController(text: actual);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    if (nuevo != null && nuevo.isNotEmpty && context.mounted) {
      final uid = context.read<AppState>().firebaseUser!.uid;
      await context.read<FundService>().updateUserProfile(uid, nombre: nuevo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final appUser = appState.appUser;
    if (appUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    appUser.nombre.isNotEmpty ? appUser.nombre[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appUser.nombre, style: theme.textTheme.titleLarge),
                      Text(appUser.email, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _editarNombre(context, appUser.nombre),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (appUser.fondoCompartidoId != null) ...[
              _PozoCompartidoSection(fundId: appUser.fondoCompartidoId!, myUid: appUser.uid),
              const SizedBox(height: 20),
            ],
            Text('Mis fondos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _SaldoFondo(
              icon: Icons.handshake_rounded,
              label: 'Couple',
              fundId: appUser.fondoCompartidoId,
            ),
            _SaldoFondo(
              icon: Icons.person_rounded,
              label: 'Mi fondo personal',
              fundId: appUser.fondoPersonalId,
            ),
            const SizedBox(height: 28),
            Text('Apariencia', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _TemaSelector(actual: appUser.tema),
            const SizedBox(height: 28),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => context.read<AuthService>().signOut(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solo se muestra contenido una vez que "Couple" existe DE VERDAD (2
/// miembros) — mientras el código está pendiente de que la pareja lo
/// canjee, no hay nada que mostrar acá (esa espera se maneja en la
/// pantalla de Inicio, no en Perfil).
class _PozoCompartidoSection extends StatelessWidget {
  const _PozoCompartidoSection({required this.fundId, required this.myUid});

  final String fundId;
  final String myUid;

  Future<void> _confirmarSalir(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir del fondo compartido?'),
        content: const Text(
          'Se borra "Couple" para los dos: el historial de gastos y depósitos '
          'compartidos deja de estar disponible. Esto no se puede deshacer. '
          'Tu "Mi fondo" personal no se toca.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      await context.read<FundService>().leaveSharedFund(uid: myUid, fundId: fundId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Fund?>(
      stream: context.read<FundService>().streamFund(fundId),
      builder: (context, snapshot) {
        final fund = snapshot.data;
        if (fund == null || fund.members.length < 2) return const SizedBox.shrink();

        final partner = fund.partnerName(myUid);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pozo compartido', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (partner != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Compartiendo con', style: theme.textTheme.bodyMedium),
                  Text(partner, style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Miembro desde', style: theme.textTheme.bodyMedium),
                Text(DateFormat('MMMM yyyy', 'es').format(fund.fechaCreacion), style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => _confirmarSalir(context),
              child: const Text('Salir del fondo compartido'),
            ),
          ],
        );
      },
    );
  }
}

class _SaldoFondo extends StatelessWidget {
  const _SaldoFondo({required this.icon, required this.label, required this.fundId});

  final IconData icon;
  final String label;
  final String? fundId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (fundId == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: theme.disabledColor),
        title: Text(label),
        trailing: const Text('—'),
      );
    }
    final mesReferencia = AppTransaction.mesReferenciaFor(DateTime.now());
    return StreamBuilder<List<AppTransaction>>(
      stream: context.read<FundService>().streamTransactions(fundId!, mesReferencia: mesReferencia),
      builder: (context, snapshot) {
        final txs = snapshot.data ?? [];
        double saldo = 0;
        for (final t in txs) {
          saldo += t.tipo == TransactionType.gasto ? -t.monto : t.monto;
        }
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(label),
          trailing: Text(Currency.format(saldo), style: theme.textTheme.titleMedium),
        );
      },
    );
  }
}

class _TemaSelector extends StatelessWidget {
  const _TemaSelector({required this.actual});
  final AppThemeMode actual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _Opt(icon: Icons.light_mode_rounded, label: 'Claro', mode: AppThemeMode.claro, actual: actual)),
          Expanded(child: _Opt(icon: Icons.dark_mode_rounded, label: 'Oscuro', mode: AppThemeMode.oscuro, actual: actual)),
          Expanded(child: _Opt(icon: Icons.brightness_auto_rounded, label: 'Auto', mode: AppThemeMode.auto, actual: actual)),
        ],
      ),
    );
  }
}

class _Opt extends StatelessWidget {
  const _Opt({required this.icon, required this.label, required this.mode, required this.actual});
  final IconData icon;
  final String label;
  final AppThemeMode mode;
  final AppThemeMode actual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = mode == actual;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final uid = context.read<AppState>().firebaseUser!.uid;
        context.read<FundService>().updateTheme(uid, mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.scaffoldBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? theme.colorScheme.primary : theme.disabledColor),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? theme.colorScheme.onSurface : theme.disabledColor,
            )),
          ],
        ),
      ),
    );
  }
}
