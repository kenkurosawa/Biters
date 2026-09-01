import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

/// Pantalla intermedia obligatoria post-registro: bloquea el acceso a las
/// funciones principales hasta que el email esté verificado.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  String? _mensaje;

  Future<void> _reenviar() async {
    setState(() {
      _sending = true;
      _mensaje = null;
    });
    try {
      await context.read<AuthService>().resendVerificationEmail();
      setState(() => _mensaje = 'Te reenviamos el correo de verificación.');
    } catch (_) {
      setState(() => _mensaje = 'No pudimos reenviar el correo. Probá de nuevo en un momento.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _yaLoVerifique() async {
    setState(() {
      _checking = true;
      _mensaje = null;
    });
    final appState = context.read<AppState>();
    final verificado = await context.read<AuthService>().reloadAndCheckVerified();
    appState.refreshFirebaseUser();
    if (mounted) {
      setState(() {
        _checking = false;
        if (!verificado) _mensaje = 'Todavía no detectamos la verificación. ¿Ya tocaste el link del email?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = context.watch<AppState>().firebaseUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread_rounded, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('Verificá tu email', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Te mandamos un correo a $email. Abrilo y tocá el link de confirmación '
                'para poder usar Biters.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (_mensaje != null) ...[
                const SizedBox(height: 16),
                Text(_mensaje!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _checking ? null : _yaLoVerifique,
                child: _checking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Ya lo verifiqué'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _sending ? null : _reenviar,
                child: Text(_sending ? 'Enviando...' : 'Reenviar correo'),
              ),
              TextButton(
                onPressed: () => context.read<AuthService>().signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
