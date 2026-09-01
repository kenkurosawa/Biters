import 'package:flutter/material.dart';
import '../utils/currency.dart';

/// Tarjeta principal de saldo disponible, en degradé — "es el elemento con
/// más peso visual de toda la app" (docs/Biters_Diseno_App.pdf, página 2).
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.saldoDisponible,
    required this.totalPositivo,
    required this.totalGastado,
    required this.labelPositivo,
    required this.baseColor,
  });

  final double saldoDisponible;
  final double totalPositivo;
  final double totalGastado;
  final String labelPositivo;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final total = totalPositivo <= 0 ? 1.0 : totalPositivo;
    final usado = (totalGastado / total).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, Colors.black, 0.25)!],
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SALDO DISPONIBLE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Currency.format(saldoDisponible),
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: usado,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(label: labelPositivo, value: totalPositivo),
              ),
              Expanded(
                child: _Stat(label: 'Gastado', value: totalGastado),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: Currency.format(value),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
