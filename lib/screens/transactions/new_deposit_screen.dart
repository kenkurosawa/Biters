import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_transaction.dart';
import '../../models/fund.dart';
import '../../services/fund_service.dart';
import '../../state/app_state.dart';
import '../../widgets/amount_field.dart';

/// Pantalla 9 del PDF: "Nuevo depósito".
class NewDepositScreen extends StatefulWidget {
  const NewDepositScreen({super.key});

  @override
  State<NewDepositScreen> createState() => _NewDepositScreenState();
}

class _NewDepositScreenState extends State<NewDepositScreen> {
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  String? _depositanteUid;
  bool _guardando = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
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

  Future<void> _guardar() async {
    final appState = context.read<AppState>();
    final fundId = appState.activeFundId;
    final uid = appState.firebaseUser?.uid;
    final nombre = appState.appUser?.nombre ?? '';
    if (fundId == null || uid == null) return;

    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un monto válido.')),
      );
      return;
    }

    setState(() => _guardando = true);
    final tx = AppTransaction(
      id: '',
      tipo: TransactionType.deposito,
      monto: monto,
      descripcion: _notaCtrl.text.trim().isEmpty ? 'Depósito' : _notaCtrl.text.trim(),
      categoria: 'Depósito',
      registradoPor: uid,
      registradoPorNombre: nombre,
      depositante: _depositanteUid ?? uid,
      fecha: _fecha,
      mesReferencia: AppTransaction.mesReferenciaFor(_fecha),
    );
    try {
      await context.read<FundService>().addTransaction(fundId, tx);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el depósito. Probá de nuevo.')),
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
    final esPersonal = appState.isPersonalActive;
    final uid = appState.firebaseUser?.uid;
    _depositanteUid ??= uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo depósito')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmountField(controller: _montoCtrl),
              Center(child: Text('Monto depositado', style: theme.textTheme.labelSmall)),
              const SizedBox(height: 20),
              if (!esPersonal && appState.activeFundId != null) ...[
                Text('¿QUIÉN DEPOSITA?', style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                StreamBuilder<Fund?>(
                  stream: context.read<FundService>().streamFund(appState.activeFundId),
                  builder: (context, snapshot) {
                    final members = snapshot.data?.members ?? [uid ?? ''];
                    return Row(
                      children: members.map((m) {
                        final soyYo = m == uid;
                        final label = soyYo ? (appState.appUser?.nombre ?? 'Vos') : 'Tu pareja';
                        final selected = _depositanteUid == m;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: selected ? theme.colorScheme.secondary : null,
                                foregroundColor: selected ? Colors.white : theme.colorScheme.secondary,
                                side: BorderSide(color: theme.colorScheme.secondary),
                              ),
                              onPressed: () => setState(() => _depositanteUid = m),
                              child: Text(label),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              Text('FECHA', style: theme.textTheme.labelSmall),
              const SizedBox(height: 6),
              InkWell(
                onTap: _elegirFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Text(DateFormat("d 'de' MMMM, yyyy", 'es').format(_fecha)),
                ),
              ),
              const SizedBox(height: 20),
              Text('NOTA (OPCIONAL)', style: theme.textTheme.labelSmall),
              const SizedBox(height: 6),
              TextField(controller: _notaCtrl, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar depósito'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
