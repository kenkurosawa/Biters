import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_transaction.dart';
import '../theme/colors.dart';
import '../utils/category_icons.dart';
import '../utils/currency.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx, this.onTap});

  final AppTransaction tx;
  final VoidCallback? onTap;

  bool get _esPositivo => tx.tipo != TransactionType.gasto;

  String get _iconKey {
    if (tx.tipo == TransactionType.deposito) return 'deposito';
    final normalized = tx.categoria.toLowerCase().replaceAll(' ', '_');
    return normalized;
  }

  String get _subtitulo {
    final hora = DateFormat.Hm('es').format(tx.fecha);
    final autor = tx.registradoPorNombre;
    return autor.isEmpty ? hora : '$hora · $autor';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _esPositivo ? BitersColors.success : theme.colorScheme.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(categoryIconFor(_iconKey), color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.descripcion.isEmpty ? tx.categoria : tx.descripcion,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(_subtitulo, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            Text(
              Currency.formatSigned(tx.monto, positive: _esPositivo),
              style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
