import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Which metal's nisab decides whether zakat is due.
enum NisabStandard { gold, silver }

/// What the user owns and owes. Money values are in the selected currency;
/// gold and silver are in grams. Every field is optional (0 = none).
class ZakatInputs {
  final double cash;
  final double goldGrams;
  final double silverGrams;
  final double investments;
  final double businessStock;
  final double receivables;
  final double debts;

  const ZakatInputs({
    this.cash = 0,
    this.goldGrams = 0,
    this.silverGrams = 0,
    this.investments = 0,
    this.businessStock = 0,
    this.receivables = 0,
    this.debts = 0,
  });

  Map<String, dynamic> toMap() => {
        'cash': cash,
        'goldGrams': goldGrams,
        'silverGrams': silverGrams,
        'investments': investments,
        'businessStock': businessStock,
        'receivables': receivables,
        'debts': debts,
      };

  factory ZakatInputs.fromMap(Map<String, dynamic> map) {
    double read(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return ZakatInputs(
      cash: read('cash'),
      goldGrams: read('goldGrams'),
      silverGrams: read('silverGrams'),
      investments: read('investments'),
      businessStock: read('businessStock'),
      receivables: read('receivables'),
      debts: read('debts'),
    );
  }
}

/// Gold and silver price per gram in [currency], and when it was taken.
class MetalPrices {
  final String currency;
  final double goldPerGram;
  final double silverPerGram;
  final DateTime asOf;

  /// True when the user typed the prices in rather than fetching them.
  final bool isManual;

  const MetalPrices({
    required this.currency,
    required this.goldPerGram,
    required this.silverPerGram,
    required this.asOf,
    this.isManual = false,
  });

  Map<String, dynamic> toMap() => {
        'currency': currency,
        'goldPerGram': goldPerGram,
        'silverPerGram': silverPerGram,
        'asOf': asOf.toIso8601String(),
        'isManual': isManual,
      };

  static MetalPrices? fromMap(Map<String, dynamic> map) {
    final gold = (map['goldPerGram'] as num?)?.toDouble();
    final silver = (map['silverPerGram'] as num?)?.toDouble();
    final asOf = DateTime.tryParse(map['asOf'] as String? ?? '');
    final currency = map['currency'] as String?;
    if (gold == null || silver == null || asOf == null || currency == null) return null;
    return MetalPrices(
      currency: currency,
      goldPerGram: gold,
      silverPerGram: silver,
      asOf: asOf,
      isManual: map['isManual'] as bool? ?? false,
    );
  }
}

/// The full breakdown of one calculation.
class ZakatResult {
  final double cash;
  final double goldValue;
  final double silverValue;
  final double investments;
  final double businessStock;
  final double receivables;
  final double totalAssets;
  final double debts;

  /// Assets minus debts due now, never below 0.
  final double zakatableWealth;
  final double goldNisabValue;
  final double silverNisabValue;
  final NisabStandard standard;
  final bool isDue;

  /// 2.5% of [zakatableWealth] when [isDue], otherwise 0.
  final double zakatDue;

  const ZakatResult({
    required this.cash,
    required this.goldValue,
    required this.silverValue,
    required this.investments,
    required this.businessStock,
    required this.receivables,
    required this.totalAssets,
    required this.debts,
    required this.zakatableWealth,
    required this.goldNisabValue,
    required this.silverNisabValue,
    required this.standard,
    required this.isDue,
    required this.zakatDue,
  });

  double get nisabValue => standard == NisabStandard.gold ? goldNisabValue : silverNisabValue;
}

/// Zakat math, live gold/silver prices, and the saved last calculation.
///
/// The math ([calculate]) is pure and static so it can be unit-tested
/// without storage or network.
class ZakatService {
  /// 20 mithqal of gold and 200 dirhams of silver.
  static const double goldNisabGrams = 87.48;
  static const double silverNisabGrams = 612.36;
  static const double zakatRate = 0.025;
  static const double gramsPerTroyOunce = 31.1034768;

  static ZakatResult calculate(ZakatInputs inputs, MetalPrices prices, NisabStandard standard) {
    // Negative entries make no sense here; treat them as nothing.
    double clean(double v) => v.isFinite && v > 0 ? v : 0;
    final goldPrice = clean(prices.goldPerGram);
    final silverPrice = clean(prices.silverPerGram);

    final cash = clean(inputs.cash);
    final goldValue = clean(inputs.goldGrams) * goldPrice;
    final silverValue = clean(inputs.silverGrams) * silverPrice;
    final investments = clean(inputs.investments);
    final businessStock = clean(inputs.businessStock);
    final receivables = clean(inputs.receivables);
    final debts = clean(inputs.debts);

    final totalAssets = cash + goldValue + silverValue + investments + businessStock + receivables;
    final zakatable = totalAssets - debts > 0 ? totalAssets - debts : 0.0;
    final goldNisab = goldNisabGrams * goldPrice;
    final silverNisab = silverNisabGrams * silverPrice;
    final nisab = standard == NisabStandard.gold ? goldNisab : silverNisab;
    // Without a price there's no nisab to compare against, so nothing is
    // reported as due.
    final isDue = nisab > 0 && zakatable >= nisab;

    return ZakatResult(
      cash: cash,
      goldValue: goldValue,
      silverValue: silverValue,
      investments: investments,
      businessStock: businessStock,
      receivables: receivables,
      totalAssets: totalAssets,
      debts: debts,
      zakatableWealth: zakatable,
      goldNisabValue: goldNisab,
      silverNisabValue: silverNisab,
      standard: standard,
      isDue: isDue,
      zakatDue: isDue ? zakatable * zakatRate : 0,
    );
  }

  /// Parses a typed amount: accepts Arabic-Indic and Persian digits, a comma
  /// or Arabic decimal separator, and ignores thousands separators/spaces.
  /// Empty or invalid input is 0.
  static double parseAmount(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    var s = buffer.toString().replaceAll(RegExp(r'[\s٬  ]'), '').replaceAll('٫', '.');
    // "1,234.5" -> thousands commas; "12,5" -> a decimal comma.
    if (s.contains('.')) {
      s = s.replaceAll(',', '');
    } else if (RegExp(r'^\d+,\d{1,2}$').hasMatch(s)) {
      s = s.replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
    final value = double.tryParse(s);
    return value != null && value.isFinite && value > 0 ? value : 0;
  }

  // ---------------------------------------------------------------------------
  // Currency
  // ---------------------------------------------------------------------------

  /// Currencies offered in the picker (ISO 4217).
  static const List<String> currencies = [
    'PKR', 'INR', 'BDT', 'USD', 'GBP', 'EUR', 'SAR', 'AED', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'EGP', 'MAD',
    'TRY', 'IDR', 'MYR', 'SGD', 'CNY', 'NGN', 'ZAR', 'KES', 'CAD', 'AUD', 'NZD', 'CHF', 'SEK', 'NOK', 'DKK',
  ];

  static const Map<String, String> _currencyByCountry = {
    'PK': 'PKR', 'IN': 'INR', 'BD': 'BDT', 'US': 'USD', 'GB': 'GBP', 'SA': 'SAR', 'AE': 'AED', 'QA': 'QAR',
    'KW': 'KWD', 'BH': 'BHD', 'OM': 'OMR', 'JO': 'JOD', 'EG': 'EGP', 'MA': 'MAD', 'TR': 'TRY', 'ID': 'IDR',
    'MY': 'MYR', 'SG': 'SGD', 'CN': 'CNY', 'NG': 'NGN', 'ZA': 'ZAR', 'KE': 'KES', 'CA': 'CAD', 'AU': 'AUD',
    'NZ': 'NZD', 'CH': 'CHF', 'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK',
    // Eurozone
    'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR', 'ES': 'EUR', 'NL': 'EUR', 'BE': 'EUR', 'AT': 'EUR', 'IE': 'EUR',
    'PT': 'EUR', 'FI': 'EUR', 'GR': 'EUR', 'LU': 'EUR', 'SK': 'EUR', 'SI': 'EUR', 'EE': 'EUR', 'LV': 'EUR',
    'LT': 'EUR', 'CY': 'EUR', 'MT': 'EUR', 'HR': 'EUR',
  };

  /// The currency for an ISO country code, USD when unknown.
  static String currencyForCountry(String? countryCode) =>
      _currencyByCountry[countryCode?.trim().toUpperCase()] ?? 'USD';

  // ---------------------------------------------------------------------------
  // Live prices
  // ---------------------------------------------------------------------------

  // fawazahmed0/exchange-api: free, no key, daily rates including XAU/XAG
  // (price of one troy ounce). The second host is its documented fallback.
  static const List<String> _priceHosts = [
    'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies',
    'https://latest.currency-api.pages.dev/v1/currencies',
  ];
  static const _timeout = Duration(seconds: 12);

  static const _fetchedPricesKey = 'zakat_fetched_prices';
  static const _manualPricesKey = 'zakat_manual_prices';
  static const _lastCalculationKey = 'zakat_last_calculation';

  final http.Client _http;

  ZakatService({http.Client? client}) : _http = client ?? http.Client();

  /// Fetches today's gold and silver price per gram for every supported
  /// currency and caches them, so switching currency later works offline.
  /// Returns the price in [currency], or null if every host failed.
  Future<MetalPrices?> fetchPrices(String currency) async {
    for (final host in _priceHosts) {
      try {
        final gold = await _fetchOunceRates('$host/xau.min.json', 'xau');
        final silver = await _fetchOunceRates('$host/xag.min.json', 'xag');
        final perGram = <String, Map<String, double>>{};
        for (final code in currencies) {
          final g = gold.rates[code.toLowerCase()];
          final s = silver.rates[code.toLowerCase()];
          if (g == null || s == null || g <= 0 || s <= 0) continue;
          perGram[code] = {'gold': g / gramsPerTroyOunce, 'silver': s / gramsPerTroyOunce};
        }
        if (perGram.isEmpty) continue;
        await VoidStorage().saveData(_fetchedPricesKey, {
          'asOf': gold.date.toIso8601String(),
          'prices': perGram,
        });
        return cachedFetchedPrices(currency);
      } catch (e) {
        VoidLogger.warning('Metal price fetch from $host failed: $e');
      }
    }
    return null;
  }

  Future<({DateTime date, Map<String, double> rates})> _fetchOunceRates(String url, String metal) async {
    final response = await _http.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = (json[metal] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()));
    final date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    return (date: date, rates: rates);
  }

  /// The last fetched prices in [currency], or null if none were cached for it.
  MetalPrices? cachedFetchedPrices(String currency) {
    try {
      final stored = VoidStorage().readData<Map<String, dynamic>>(_fetchedPricesKey);
      if (stored == null) return null;
      final asOf = DateTime.tryParse(stored['asOf'] as String? ?? '');
      final entry = (stored['prices'] as Map?)?[currency] as Map?;
      final gold = (entry?['gold'] as num?)?.toDouble();
      final silver = (entry?['silver'] as num?)?.toDouble();
      if (asOf == null || gold == null || silver == null) return null;
      return MetalPrices(currency: currency, goldPerGram: gold, silverPerGram: silver, asOf: asOf);
    } catch (e) {
      VoidLogger.error('Cached metal prices were unreadable', e);
      return null;
    }
  }

  /// Prices the user typed for [currency], or null.
  MetalPrices? manualPrices(String currency) {
    try {
      final stored = VoidStorage().readData<Map<String, dynamic>>(_manualPricesKey);
      final entry = stored?[currency];
      if (entry is! Map) return null;
      return MetalPrices.fromMap(Map<String, dynamic>.from(entry));
    } catch (e) {
      VoidLogger.error('Manual metal prices were unreadable', e);
      return null;
    }
  }

  Future<void> saveManualPrices(MetalPrices prices) async {
    final stored = Map<String, dynamic>.from(VoidStorage().readData<Map<String, dynamic>>(_manualPricesKey) ?? {});
    stored[prices.currency] = prices.toMap();
    await VoidStorage().saveData(_manualPricesKey, stored);
  }

  /// Drops typed prices for [currency], e.g. after the user asks for the live
  /// price again.
  Future<void> clearManualPrices(String currency) async {
    final stored = Map<String, dynamic>.from(VoidStorage().readData<Map<String, dynamic>>(_manualPricesKey) ?? {});
    stored.remove(currency);
    await VoidStorage().saveData(_manualPricesKey, stored);
  }

  /// The newest prices known for [currency], manual or fetched.
  MetalPrices? bestKnownPrices(String currency) {
    final manual = manualPrices(currency);
    final fetched = cachedFetchedPrices(currency);
    if (manual == null) return fetched;
    if (fetched == null) return manual;
    return manual.asOf.isAfter(fetched.asOf) ? manual : fetched;
  }

  // ---------------------------------------------------------------------------
  // Last calculation
  // ---------------------------------------------------------------------------

  Future<void> saveLastCalculation({
    required ZakatInputs inputs,
    required String currency,
    required NisabStandard standard,
  }) {
    return VoidStorage().saveData(_lastCalculationKey, {
      'inputs': inputs.toMap(),
      'currency': currency,
      'standard': standard.name,
    });
  }

  ({ZakatInputs inputs, String currency, NisabStandard standard})? loadLastCalculation() {
    try {
      final stored = VoidStorage().readData<Map<String, dynamic>>(_lastCalculationKey);
      if (stored == null) return null;
      final currency = stored['currency'] as String?;
      return (
        inputs: ZakatInputs.fromMap(Map<String, dynamic>.from(stored['inputs'] as Map? ?? {})),
        currency: currencies.contains(currency) ? currency! : 'USD',
        standard: stored['standard'] == NisabStandard.gold.name ? NisabStandard.gold : NisabStandard.silver,
      );
    } catch (e) {
      VoidLogger.error('Saved zakat calculation was unreadable', e);
      return null;
    }
  }

  Future<void> clearLastCalculation() => VoidStorage().removeData(_lastCalculationKey);
}
