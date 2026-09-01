import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_transaction.dart';
import '../../services/fund_service.dart';
import '../../theme/colors.dart';
import '../../utils/category_icons.dart';
import '../../utils/currency.dart';

/// Pantalla 10 del PDF: detalle de un gasto/ingreso/depósito. Ver, editar,
/// eliminar; si es gasto rápido, permite agregar el detalle por ítems
/// (validando que la suma coincida con el total ya cargado).
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.fundId, required this.transactionId});

  final String fundId;
  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final fundService = FundService();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del gasto')),
      body: StreamBuilder<AppTransaction>(
        stream: FirebaseFirestore.instance
            .collection('funds')
            .doc(fundId)
            .collection('transactions')
            .doc(transactionId)
            .snapshots()
            .where((d) => d.exists)
            .map(AppTransaction.fromDoc),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final tx = snapshot.data!;
          return _DetailBody(fundId: fundId, tx: tx, fundService: fundService);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.fundId, required this.tx, required this.fundService});

  final String fundId;
  final AppTransaction tx;
  final FundService fundService;

  bool get _esPositivo => tx.tipo != TransactionType.gasto;

  Future<void> _eliminar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar este movimiento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BitersColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await fundService.deleteTransaction(fundId, tx.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _editar(BuildContext context) async {
    final montoCtrl = TextEditingController(text: tx.monto.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: tx.descripcion);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Editar movimiento', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto', prefixText: 'Gs. '),
            ),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      final monto = double.tryParse(montoCtrl.text) ?? tx.monto;
      final updated = AppTransaction(
        id: tx.id,
        tipo: tx.tipo,
        monto: monto,
        descripcion: descCtrl.text.trim(),
        categoria: tx.categoria,
        modo: tx.modo,
        items: tx.items,
        registradoPor: tx.registradoPor,
        registradoPorNombre: tx.registradoPorNombre,
        depositante: tx.depositante,
        fecha: tx.fecha,
        mesReferencia: tx.mesReferencia,
      );
      await fundService.updateTransaction(fundId, updated);
    }
  }

  Future<void> _agregarDetalle(BuildContext context) async {
    final items = <TransactionItem>[];
    double restante = tx.monto;

    bool seguirAgregando = true;
    while (seguirAgregando && context.mounted) {
      // El `while` ya vuelve a chequear context.mounted en cada vuelta.
      final item = await showDialog<TransactionItem>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => _AddItemDialog(restante: restante),
      );
      if (item == null) break;
      items.add(item);
      restante -= item.monto;
      if (restante <= 0) break;
      if (!context.mounted) break;
      seguirAgregando = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Quedan ${Currency.format(restante)}'),
              content: const Text('¿Agregar otro ítem?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Listo')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Agregar otro')),
              ],
            ),
          ) ??
          false;
    }

    if (items.isEmpty) return;
    final suma = items.fold(0.0, (s, i) => s + i.monto);
    if (suma != tx.monto) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La suma de los ítems (${Currency.format(suma)}) no coincide con el total '
              '(${Currency.format(tx.monto)}). No se guardó.',
            ),
          ),
        );
      }
      return;
    }

    final updated = AppTransaction(
      id: tx.id,
      tipo: tx.tipo,
      monto: tx.monto,
      descripcion: tx.descripcion,
      categoria: tx.categoria,
      modo: ExpenseMode.detallado,
      items: items,
      registradoPor: tx.registradoPor,
      registradoPorNombre: tx.registradoPorNombre,
      depositante: tx.depositante,
      fecha: tx.fecha,
      mesReferencia: tx.mesReferencia,
    );
    await fundService.updateTransaction(fundId, updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _esPositivo ? BitersColors.success : theme.colorScheme.error;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIconFor(tx.categoria.toLowerCase()), size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              Currency.formatSigned(tx.monto, positive: _esPositivo),
              style: theme.textTheme.displayLarge?.copyWith(color: color),
            ),
            Text(tx.descripcion.isEmpty ? tx.categoria : tx.descripcion, style: theme.textTheme.titleMedium),
            if (tx.isGastoRapidoSinItems) ...[
              const SizedBox(height: 8),
              Chip(
                label: const Text('CARGADO RÁPIDO · SIN ÍTEMS'),
                backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.12),
                labelStyle: TextStyle(color: theme.colorScheme.secondary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 24),
            _InfoRow(label: 'Categoría', value: tx.categoria),
            _InfoRow(label: 'Fecha', value: DateFormat("d MMM yyyy, HH:mm", 'es').format(tx.fecha)),
            _InfoRow(label: 'Registrado por', value: tx.registradoPorNombre),
            _InfoRow(label: 'Mes', value: tx.mesReferencia),
            if (tx.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: Text('Ítems', style: theme.textTheme.labelSmall)),
              for (final item in tx.items)
                _InfoRow(label: item.subcategoria, value: Currency.format(item.monto)),
            ],
            const SizedBox(height: 20),
            if (tx.isGastoRapidoSinItems)
              OutlinedButton.icon(
                onPressed: () => _agregarDetalle(context),
                icon: const Icon(Icons.add),
                label: const Text('Agregar detalle por ítems'),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editar(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: BitersColors.danger),
                    onPressed: () => _eliminar(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog({required this.restante});
  final double restante;

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _subCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ítem (quedan ${Currency.format(widget.restante)})'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _subCtrl, decoration: const InputDecoration(labelText: 'Subcategoría')),
          const SizedBox(height: 12),
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto', prefixText: 'Gs. '),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final monto = double.tryParse(_montoCtrl.text) ?? 0;
            if (_subCtrl.text.trim().isEmpty || monto <= 0) return;
            Navigator.pop(context, TransactionItem(subcategoria: _subCtrl.text.trim(), monto: monto));
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
