import 'package:flutter_test/flutter_test.dart';
import 'package:biters/utils/currency.dart';
import 'package:biters/models/app_transaction.dart';
import 'package:biters/widgets/amount_field.dart';

void main() {
  test('AmountField.parse quita los separadores de miles', () {
    expect(AmountField.parse('4.500.000'), 4500000);
    expect(AmountField.parse('0'), 0);
    expect(AmountField.parse(''), 0);
    expect(AmountField.parse('120'), 120);
  });


  test('Currency.format usa separador de miles y sin decimales', () {
    expect(Currency.format(1250000), 'Gs. 1.250.000');
  });

  test('Currency.formatSigned agrega +/- según el signo', () {
    expect(Currency.formatSigned(120000, positive: false), '- Gs. 120.000');
    expect(Currency.formatSigned(500000, positive: true), '+ Gs. 500.000');
  });

  test('mesReferenciaFor arma el string YYYY-MM', () {
    expect(AppTransaction.mesReferenciaFor(DateTime(2026, 9, 1)), '2026-09');
    expect(AppTransaction.mesReferenciaFor(DateTime(2026, 1, 15)), '2026-01');
  });
}
