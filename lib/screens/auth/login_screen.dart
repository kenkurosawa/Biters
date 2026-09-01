import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/biters_logo.dart';

enum _AuthMode { iniciarSesion, crearCuenta }

/// Pantalla 1/2 del PDF: toggle "Iniciar sesión / Crear cuenta".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  _AuthMode _mode = _AuthMode.iniciarSesion;
  bool _loading = false;
  String? _error;

  int _failedAttempts = 0;
  DateTime? _cooldownUntil;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _enCooldown => _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  Future<void> _submit() async {
    if (_enCooldown) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();
    try {
      if (_mode == _AuthMode.iniciarSesion) {
        await auth.signIn(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
        _failedAttempts = 0;
      } else {
        await auth.signUp(
          nombre: _nombreCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
      // La navegación post-login la resuelve el redirect de GoRouter según
      // el estado de auth/verificación (ver lib/router.dart).
    } on FirebaseAuthException catch (e) {
      if (_mode == _AuthMode.iniciarSesion) {
        _failedAttempts++;
        // Cooldown básico en el cliente tras varios intentos fallidos
        // seguidos (además del rate limiting de fábrica de Firebase Auth).
        if (_failedAttempts >= 5) {
          _cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
          _failedAttempts = 0;
        }
      }
      setState(() => _error = _mensajeError(e));
    } catch (_) {
      setState(() => _error = 'Ocurrió un error. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mensajeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese email.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 8 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá un momento y probá de nuevo.';
      default:
        return 'No se pudo completar la operación. Probá de nuevo.';
    }
  }

  Future<void> _recuperarPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresá tu email arriba para poder enviarte el link.');
      return;
    }
    try {
      await context.read<AuthService>().sendPasswordResetEmail(_emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te enviamos un email para recuperar tu contraseña.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Si el email existe, vas a recibir un link en breve.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esLogin = _mode == _AuthMode.iniciarSesion;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: BitersLogo()),
                const SizedBox(height: 12),
                Text(
                  'Biters',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  esLogin ? 'El pozo de nosotros dos,\npara cenas y salidas.' : 'Creá tu cuenta para empezar',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                _ModeToggle(
                  mode: _mode,
                  onChanged: (m) => setState(() {
                    _mode = m;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 24),
                if (!esLogin) ...[
                  Text('NOMBRE', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                Text('CORREO', style: theme.textTheme.labelSmall),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Ingresá un email válido' : null,
                ),
                const SizedBox(height: 16),
                Text('CONTRASEÑA', style: theme.textTheme.labelSmall),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_passwordVisible,
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Mínimo 8 caracteres'
                      : null,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),
                if (esLogin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _recuperarPassword,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                ] else
                  const SizedBox(height: 8),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                if (_enCooldown) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Demasiados intentos fallidos. Esperá unos segundos antes de volver a intentar.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_loading || _enCooldown) ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(esLogin ? 'Ingresar' : 'Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Iniciar sesión',
              selected: mode == _AuthMode.iniciarSesion,
              onTap: () => onChanged(_AuthMode.iniciarSesion),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Crear cuenta',
              selected: mode == _AuthMode.crearCuenta,
              onTap: () => onChanged(_AuthMode.crearCuenta),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.selected, required this.onTap});

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
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? theme.colorScheme.onSurface : theme.disabledColor,
          ),
        ),
      ),
    );
  }
}
