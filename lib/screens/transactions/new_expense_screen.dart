import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_transaction.dart';
import '../../models/category.dart';
import '../../services/fund_service.dart';
import '../../state/app_state.dart';
import '../../widgets/category_chip_selector.dart';

/// Pantallas 6 y 7 del PDF: "Nuevo gasto" en modo Rápido o Detallado.
class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  ExpenseMode _modo = ExpenseMode.rapido;
  final _montoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  String? _categoria;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  final List<TransactionItem> _items = [];

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  double get _totalItems => _items.fold(0.0, (sum, i) => sum + i.monto);

  Future<void> _agregarItem() async {
    final result = await showDialog<TransactionItem>(
      context: context,
      builder: (_) => const _ItemDialog(),
    );
    if (result != null) setState(() => _items.add(result));
  }

  Future<void> _elegirFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_fecha));
    setState(() {
      _fecha = DateTime(date.year, date.month, date.day, time?.hour ?? _fecha.hour, time?.minute ?? _fecha.minute);
    });
  }

  Future<void> _crearCategoria() async {
    final nombre = await showDialog<String>(context: context, builder: (_) => const _NuevaCategoriaDialog());
    if (nombre == null || nombre.trim().isEmpty || !mounted) return;
    final appState = context.read<AppState>();
    final fundId = appState.activeFundId;
    if (fundId == null) return;
    await context.read<FundService>().addCustomCategory(fundId, esIngreso: false, nombre: nombre.trim());
    setState(() => _categoria = nombre.trim());
  }

  Future<void> _guardar() async {
    final appState = context.read<AppState>();
    final fundId = appState.activeFundId;
    final uid = appState.firebaseUser?.uid;
    final nombre = appState.appUser?.nombre ?? '';
    if (fundId == null || uid == null) return;

    final double monto = _modo == ExpenseMode.detallado
        ? _totalItems
        : (double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0);

    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un monto válido.')),
      );
      return;
    }
    if (_categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí una categoría.')),
      );
      return;
    }
    if (_modo == ExpenseMode.detallado && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregá al menos un ítem.')),
      );
      return;
    }

    setState(() => _guardando = true);
    final tx = AppTransaction(
      id: '',
      tipo: TransactionType.gasto,
      monto: monto,
      descripcion: _descripcionCtrl.text.trim(),
      categoria: _categoria!,
      modo: _modo,
      items: _modo == ExpenseMode.detallado ? _items : const [],
      registradoPor: uid,
      registradoPorNombre: nombre,
      fecha: _fecha,
      mesReferencia: AppTransaction.mesReferenciaFor(_fecha),
    );
    try {
      await context.read<FundService>().addTransaction(fundId, tx);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el gasto. Probá de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final fundId = appState.activeFundId;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo gasto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModoToggle(modo: _modo, onChanged: (m) => setState(() => _modo = m)),
              const SizedBox(height: 24),
              if (_modo == ExpenseMode.rapido) ...[
                Center(
                  child: TextField(
                    controller: _montoCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    style: theme.textTheme.displayLarge,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixText: 'Gs. ',
                      hintText: '0',
                    ),
                  ),
                ),
                Center(child: Text('Monto del gasto', style: theme.textTheme.labelSmall)),
                const SizedBox(height: 20),
              ] else ...[
                Text('DESCRIPCIÓN GENERAL', style: theme.textTheme.labelSmall),
                const SizedBox(height: 6),
              ],
              if (_modo == ExpenseMode.rapido) ...[
                Text('DESCRIPCIÓN', style: theme.textTheme.labelSmall),
                const SizedBox(height: 6),
              ],
              TextField(controller: _descripcionCtrl, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 20),
              Text('CATEGORÍA', style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              if (fundId != null)
                StreamBuilder(
                  stream: context.read<FundService>().streamCategories(fundId),
                  builder: (context, snapshot) {
                    final custom = snapshot.data?.gasto ?? const <AppCategory>[];
                    final todas = <AppCategory>[
                      ...AppCategory.gastoBase,
                      ...custom.where((c) => !AppCategory.gastoBase.any((b) => b.nombre == c.nombre)),
                    ];
                    return CategoryChipSelector(
                      categorias: todas,
                      seleccionada: _categoria,
                      onSelect: (n) => setState(() => _categoria = n),
                      onNueva: _crearCategoria,
                    );
                  },
                ),
              const SizedBox(height: 20),
              if (_modo == ExpenseMode.detallado) ...[
                Text('ÍTEMS DE LA FACTURA', style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                for (final item in _items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.subcategoria)),
                        Text(NumberFormat.currency(locale: 'es_PY', symbol: 'Gs. ', decimalDigits: 0)
                            .format(item.monto)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _items.remove(item)),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _agregarItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar ítem (subcategoría + monto)'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text('TOTAL (SUMA DE ÍTEMS)', style: theme.textTheme.labelSmall),
                      Text(
                        NumberFormat.currency(locale: 'es_PY', symbol: 'Gs. ', decimalDigits: 0)
                            .format(_totalItems),
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_modo == ExpenseMode.rapido) ...[
                Text('FECHA Y HORA', style: theme.textTheme.labelSmall),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _elegirFecha,
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Text(DateFormat("d 'de' MMMM, HH:mm", 'es').format(_fecha)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '💡 Podés agregarle el detalle por ítems más tarde, editando este gasto.',
                  style: theme.textTheme.labelSmall,
                ),
              ] else
                InkWell(
                  onTap: _elegirFecha,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'FECHA Y HORA'),
                    child: Text(DateFormat("d 'de' MMMM, HH:mm", 'es').format(_fecha)),
                  ),
                ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar gasto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModoToggle extends StatelessWidget {
  const _ModoToggle({required this.modo, required this.onChanged});
  final ExpenseMode modo;
  final ValueChanged<ExpenseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              icon: Icons.bolt_rounded,
              label: 'Rápido',
              selected: modo == ExpenseMode.rapido,
              onTap: () => onChanged(ExpenseMode.rapido),
            ),
          ),
          Expanded(
            child: _SegButton(
              icon: Icons.receipt_long_rounded,
              label: 'Detallado',
              selected: modo == ExpenseMode.detallado,
              onTap: () => onChanged(ExpenseMode.detallado),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({required this.icon, required this.label, required this.selected, required this.onTap});
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.scaffoldBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? theme.colorScheme.primary : theme.disabledColor),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: selected ? theme.colorScheme.onSurface : theme.disabledColor)),
          ],
        ),
      ),
    );
  }
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog();

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _subCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar ítem'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _subCtrl, decoration: const InputDecoration(labelText: 'Subcategoría (ej. Café)')),
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

class _NuevaCategoriaDialog extends StatefulWidget {
  const _NuevaCategoriaDialog();

  @override
  State<_NuevaCategoriaDialog> createState() => _NuevaCategoriaDialogState();
}

class _NuevaCategoriaDialogState extends State<_NuevaCategoriaDialog> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva categoría'),
      content: TextField(controller: _ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nombre')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Crear')),
      ],
    );
  }
}
