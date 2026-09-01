import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/invite_service.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';

/// Pantalla 14 del PDF: generar código de invitación de 6 dígitos.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  GeneratedInvite? _invite;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generar();
  }

  Future<void> _generar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appState = context.read<AppState>();
      final uid = appState.firebaseUser!.uid;
      final nombre = appState.appUser?.nombre ?? '';
      final invite = await context.read<InviteService>().generateInvite(uid, nombre: nombre);
      if (mounted) setState(() => _invite = invite);
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos generar el código. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _tiempoRestante(DateTime expiresAt) {
    final restante = expiresAt.difference(DateTime.now());
    if (restante.isNegative) return 'Vencido';
    if (restante.inHours >= 1) return 'Vence en ${restante.inHours} horas';
    return 'Vence en ${restante.inMinutes} minutos';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invitar a tu pareja')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _generar, child: const Text('Reintentar')),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.front_hand_rounded, size: 56, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Compartí este código con tu pareja\npara que se una a "Couple"',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final digit in _invite!.codigo.split(''))
                              Container(
                                width: 46,
                                height: 58,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  digit,
                                  style: const TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                    color: BitersColors.ink,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Chip(
                          avatar: const Icon(Icons.timer_outlined, size: 16),
                          label: Text(_tiempoRestante(_invite!.expiresAt)),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _generar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generar un código nuevo'),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Compartir código'),
                          onPressed: () {
                            SharePlus.instance.share(ShareParams(
                              text: 'Unite a nuestro fondo compartido en Biters con este código: '
                                  '${_invite!.codigo} (vence en 24hs)',
                            ));
                          },
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
