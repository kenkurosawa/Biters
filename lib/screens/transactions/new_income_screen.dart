import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_transaction.dart';
import '../../models/category.dart';
import '../../services/fund_service.dart';
import '../../state/app_state.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/category_chip_selector.dart';

/// Pantalla 8 del PDF: "Nuevo ingreso", exclusiva de "Mi fondo" personal.
class NewIncomeScreen extends StatefulWidget {
  const NewIncomeScreen({super.key});

  @override
  State<NewIncomeScreen> createState() => _NewIncomeScreenState();
}

class _NewIncomeScreenState extends State<NewIncomeScreen> {
  final _montoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _detalleCtrl = TextEditingController();
  String? _categoria;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _fecha = date);
  }

  Future<void> _crearCategoria() async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
      ),
    );
    if (nombre == null || nombre.trim().isEmpty || !mounted) return;
    final fundId = context.read<AppState>().activeFundId;
    if (fundId == null) return;
    await context.read<FundService>().addCustomCategory(fundId, esIngreso: true, nombre: nombre.trim());
    setState(() => _categoria = nombre.trim());
  }

  Future<void> _guardar() async {
    final appState = context.read<AppState>();
    final fundId = appState.activeFundId;
    final uid = appState.firebaseUser?.uid;
    final nombre = appState.appUser?.nombre ?? '';
    if (fundId == null || uid == null) return;

    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;
    if (monto <= 0 || _categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá el monto y la categoría.')),
      );
      return;
    }

    setState(() => _guardando = true);
    final tx = AppTransaction(
      id: '',
      tipo: TransactionType.ingreso,
      monto: monto,
      descripcion: _descripcionCtrl.text.trim().isEmpty ? _detalleCtrl.text.trim() : _descripcionCtrl.text.trim(),
      categoria: _categoria!,
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
          const SnackBar(content: Text('No se pudo guardar el ingreso. Probá de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fundId = context.watch<AppState>().activeFundId;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo ingreso')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Solo disponible en Mi fondo personal', style: theme.textTheme.labelSmall),
              const SizedBox(height: 12),
              AmountField(controller: _montoCtrl),
              Center(child: Text('Monto del ingreso', style: theme.textTheme.labelSmall)),
              const SizedBox(height: 20),
              Text('DESCRIPCIÓN', style: theme.textTheme.labelSmall),
              const SizedBox(height: 6),
              TextField(controller: _descripcionCtrl, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 20),
              Text('CATEGORÍA DEL INGRESO', style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              if (fundId != null)
                StreamBuilder(
                  stream: context.read<FundService>().streamCategories(fundId),
                  builder: (context, snapshot) {
                    final custom = snapshot.data?.ingreso ?? const <AppCategory>[];
                    final todas = <AppCategory>[
                      ...AppCategory.ingresoBase,
                      ...custom.where((c) => !AppCategory.ingresoBase.any((b) => b.nombre == c.nombre)),
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
              Text('DETALLE (OPCIONAL)', style: theme.textTheme.labelSmall),
              const SizedBox(height: 6),
              TextField(controller: _detalleCtrl, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 20),
              Text('FECHA', style: theme.textTheme.labelSmall),
              const SizedBox(height: 6),
              InkWell(
                onTap: _elegirFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Text(DateFormat("d 'de' MMMM, yyyy", 'es').format(_fecha)),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar ingreso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
