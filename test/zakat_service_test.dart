import 'package:flutter_test/flutter_test.dart';
import 'package:allah_everywhere/services/zakat_service.dart';

/// Round numbers so expected values are easy to check by hand:
/// gold nisab = 87.48 * 100 = 8748, silver nisab = 612.36 * 1 = 612.36.
final _prices = MetalPrices(currency: 'USD', goldPerGram: 100, silverPerGram: 1, asOf: DateTime(2026, 10, 7));

ZakatResult _calc(ZakatInputs inputs, [NisabStandard standard = NisabStandard.silver]) =>
    ZakatService.calculate(inputs, _prices, standard);

void main() {
  group('ZakatService.calculate', () {
    test('nothing owned: nothing due', () {
      final r = _calc(const ZakatInputs());
      expect(r.totalAssets, 0);
      expect(r.zakatableWealth, 0);
      expect(r.isDue, isFalse);
      expect(r.zakatDue, 0);
    });

    test('nisab values come from grams x price', () {
      final r = _calc(const ZakatInputs());
      expect(r.goldNisabValue, closeTo(8748, 1e-9));
      expect(r.silverNisabValue, closeTo(612.36, 1e-9));
      expect(r.nisabValue, closeTo(612.36, 1e-9));
      expect(_calc(const ZakatInputs(), NisabStandard.gold).nisabValue, closeTo(8748, 1e-9));
    });

    test('2.5% of zakatable wealth once nisab is reached', () {
      final r = _calc(const ZakatInputs(cash: 1000));
      expect(r.isDue, isTrue);
      expect(r.zakatDue, closeTo(25, 1e-9));
    });

    test('values gold and silver by weight', () {
      final r = _calc(const ZakatInputs(goldGrams: 10, silverGrams: 200));
      expect(r.goldValue, closeTo(1000, 1e-9));
      expect(r.silverValue, closeTo(200, 1e-9));
      expect(r.totalAssets, closeTo(1200, 1e-9));
      expect(r.zakatDue, closeTo(30, 1e-9));
    });

    test('adds every asset type', () {
      final r = _calc(const ZakatInputs(
        cash: 100,
        goldGrams: 1,
        silverGrams: 10,
        investments: 200,
        businessStock: 300,
        receivables: 400,
      ));
      expect(r.totalAssets, closeTo(100 + 100 + 10 + 200 + 300 + 400, 1e-9));
    });

    test('deducts debts due now', () {
      final r = _calc(const ZakatInputs(cash: 2000, debts: 500));
      expect(r.zakatableWealth, closeTo(1500, 1e-9));
      expect(r.zakatDue, closeTo(37.5, 1e-9));
    });

    test('debts larger than assets leave 0, never negative', () {
      final r = _calc(const ZakatInputs(cash: 100, debts: 500));
      expect(r.zakatableWealth, 0);
      expect(r.isDue, isFalse);
      expect(r.zakatDue, 0);
    });

    test('debts can bring wealth below nisab', () {
      final r = _calc(const ZakatInputs(cash: 700, debts: 100));
      expect(r.zakatableWealth, closeTo(600, 1e-9));
      expect(r.isDue, isFalse);
    });

    test('the chosen standard decides whether zakat is due', () {
      const inputs = ZakatInputs(cash: 5000);
      expect(_calc(inputs, NisabStandard.silver).isDue, isTrue);
      expect(_calc(inputs, NisabStandard.gold).isDue, isFalse);
      expect(_calc(inputs, NisabStandard.gold).zakatDue, 0);
    });

    test('exactly at nisab is due', () {
      final r = _calc(const ZakatInputs(cash: 8748), NisabStandard.gold);
      expect(r.isDue, isTrue);
      expect(r.zakatDue, closeTo(218.7, 1e-9));
    });

    test('just below nisab is not due', () {
      expect(_calc(const ZakatInputs(cash: 8747.99), NisabStandard.gold).isDue, isFalse);
    });

    test('without prices nothing is reported as due', () {
      final noPrices = MetalPrices(currency: 'USD', goldPerGram: 0, silverPerGram: 0, asOf: DateTime(2026));
      final r = ZakatService.calculate(const ZakatInputs(cash: 1e9), noPrices, NisabStandard.silver);
      expect(r.nisabValue, 0);
      expect(r.isDue, isFalse);
      expect(r.zakatDue, 0);
    });

    test('negative and non-finite inputs count as nothing', () {
      final r = _calc(const ZakatInputs(cash: -500, goldGrams: double.nan, investments: double.infinity, debts: -10));
      expect(r.totalAssets, 0);
      expect(r.debts, 0);
      expect(r.zakatDue, 0);
    });
  });

  group('ZakatService.parseAmount', () {
    test('plain and decimal numbers', () {
      expect(ZakatService.parseAmount('1500'), 1500);
      expect(ZakatService.parseAmount('12.75'), 12.75);
      expect(ZakatService.parseAmount(' 3 000 '), 3000);
    });

    test('thousands commas and decimal commas', () {
      expect(ZakatService.parseAmount('1,234,567'), 1234567);
      expect(ZakatService.parseAmount('1,234.5'), 1234.5);
      expect(ZakatService.parseAmount('12,5'), 12.5);
    });

    test('Arabic-Indic and Persian digits', () {
      expect(ZakatService.parseAmount('١٢٣٤'), 1234);
      expect(ZakatService.parseAmount('۱۲۳'), 123);
      expect(ZakatService.parseAmount('١٢٫٥'), 12.5);
    });

    test('empty, invalid and negative input is 0', () {
      expect(ZakatService.parseAmount(''), 0);
      expect(ZakatService.parseAmount('abc'), 0);
      expect(ZakatService.parseAmount('-50'), 0);
    });
  });

  group('currencyForCountry', () {
    test('maps countries to their currency', () {
      expect(ZakatService.currencyForCountry('PK'), 'PKR');
      expect(ZakatService.currencyForCountry('in'), 'INR');
      expect(ZakatService.currencyForCountry('DE'), 'EUR');
      expect(ZakatService.currencyForCountry('SA'), 'SAR');
      expect(ZakatService.currencyForCountry('TR'), 'TRY');
    });

    test('falls back to USD', () {
      expect(ZakatService.currencyForCountry(null), 'USD');
      expect(ZakatService.currencyForCountry('XX'), 'USD');
    });

    test('every mapped currency is offered in the picker', () {
      for (final code in ['PK', 'IN', 'GB', 'DE', 'SA', 'AE', 'TR', 'BD', 'ID', 'MY', 'EG', 'NG']) {
        expect(ZakatService.currencies, contains(ZakatService.currencyForCountry(code)));
      }
    });
  });

  group('serialization', () {
    test('ZakatInputs round-trips', () {
      const inputs = ZakatInputs(cash: 1, goldGrams: 2, silverGrams: 3, investments: 4, businessStock: 5, receivables: 6, debts: 7);
      final back = ZakatInputs.fromMap(inputs.toMap());
      expect(back.toMap(), inputs.toMap());
    });

    test('ZakatInputs tolerates missing keys', () {
      expect(ZakatInputs.fromMap({'cash': 5}).toMap(), const ZakatInputs(cash: 5).toMap());
    });

    test('MetalPrices round-trips and rejects bad data', () {
      final back = MetalPrices.fromMap(_prices.toMap())!;
      expect(back.goldPerGram, 100);
      expect(back.asOf, _prices.asOf);
      expect(MetalPrices.fromMap({'goldPerGram': 1}), isNull);
    });
  });
}
