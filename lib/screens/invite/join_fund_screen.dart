import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/invite_service.dart';
import '../../state/app_state.dart';

/// Pantalla 15 del PDF: unirse a un fondo compartido con el código de 6
/// dígitos.
class JoinFundScreen extends StatefulWidget {
  const JoinFundScreen({super.key});

  @override
  State<JoinFundScreen> createState() => _JoinFundScreenState();
}

class _JoinFundScreenState extends State<JoinFundScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _codigo => _controllers.map((c) => c.text).join();

  Future<void> _unirme() async {
    if (_codigo.length != 6) {
      setState(() => _error = 'Completá los 6 dígitos del código.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = context.read<AppState>().firebaseUser!.uid;
      await context.read<InviteService>().redeemInvite(codigo: _codigo, joinerUid: uid);
      if (mounted) Navigator.of(context).pop();
    } on InviteException catch (e) {
      setState(() => _error = e.mensaje);
    } catch (_) {
      setState(() => _error = 'No pudimos unirte al fondo. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Unirme a un fondo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.key_rounded, size: 56, color: theme.colorScheme.secondary),
              const SizedBox(height: 16),
              Text(
                'Pedile el código de 6 dígitos\na tu pareja e ingresalo acá',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 6; i++)
                    Container(
                      width: 44,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: theme.textTheme.headlineMedium,
                        decoration: const InputDecoration(counterText: ''),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                          }
                          if (v.isEmpty && i > 0) {
                            FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
                          }
                          setState(() {});
                        },
                      ),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Text(
                'Al unirte vas a empezar a ver y compartir el fondo "Couple" '
                'con tu pareja, junto a tu "Mi fondo" personal que seguís teniendo aparte.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                onPressed: _loading ? null : _unirme,
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Unirme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
