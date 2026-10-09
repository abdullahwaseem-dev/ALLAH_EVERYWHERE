import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allah_everywhere/data/zakat_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/zakat_service.dart';
import 'package:allah_everywhere/share_cards/share_content.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/theme/scripture_text.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

enum _Field { cash, goldGrams, silverGrams, investments, businessStock, receivables, debts }

/// Zakat calculator: assets minus debts due now, compared with the gold or
/// silver nisab at today's metal price. Inputs are saved as the user types,
/// so the last calculation is there next time.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  // PrayerTimesController stores the country of the last location fix here.
  static const _prayerCountryKey = 'prayer_country_code';

  final ZakatService _service = ZakatService();
  final Map<_Field, TextEditingController> _controllers = {
    for (final f in _Field.values) f: TextEditingController(),
  };

  late String _currency;
  NisabStandard _standard = NisabStandard.silver;
  MetalPrices? _prices;
  bool _fetching = false;
  bool _fetchFailed = false;

  @override
  void initState() {
    super.initState();
    final last = _service.loadLastCalculation();
    if (last != null) {
      _currency = last.currency;
      _standard = last.standard;
      final map = last.inputs.toMap();
      for (final f in _Field.values) {
        final value = (map[f.name] as num?)?.toDouble() ?? 0;
        _controllers[f]!.text = value > 0 ? _plain(value) : '';
      }
    } else {
      // Device region first (that's where the user's money is), then the
      // country of the last prayer-times location.
      final country = WidgetsBinding.instance.platformDispatcher.locale.countryCode ??
          VoidStorage().readData<String>(_prayerCountryKey);
      _currency = ZakatService.currencyForCountry(country);
    }
    _loadPricesFor(_currency);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// A stored number back as typed text: "1500", "12.5".
  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  ZakatInputs get _inputs {
    double v(_Field f) => ZakatService.parseAmount(_controllers[f]!.text);
    return ZakatInputs(
      cash: v(_Field.cash),
      goldGrams: v(_Field.goldGrams),
      silverGrams: v(_Field.silverGrams),
      investments: v(_Field.investments),
      businessStock: v(_Field.businessStock),
      receivables: v(_Field.receivables),
      debts: v(_Field.debts),
    );
  }

  void _save() {
    _service.saveLastCalculation(inputs: _inputs, currency: _currency, standard: _standard);
  }

  /// Uses what's known for [currency] straight away, then refreshes the live
  /// price unless the user typed one in or today's price is already cached.
  /// The fetch is scheduled, not run inline, since this is called from
  /// initState and from inside setState.
  void _loadPricesFor(String currency) {
    _prices = _service.bestKnownPrices(currency);
    _fetchFailed = false;
    final prices = _prices;
    final hasManual = _service.manualPrices(currency) != null;
    if (!hasManual && (prices == null || !_isToday(prices.asOf))) {
      Future.microtask(() {
        if (mounted && currency == _currency) _refreshPrices(clearManual: false);
      });
    }
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Future<void> _refreshPrices({bool clearManual = true}) async {
    if (_fetching) return;
    setState(() {
      _fetching = true;
      _fetchFailed = false;
    });
    final currency = _currency;
    final fetched = await _service.fetchPrices(currency);
    if (fetched != null && clearManual) await _service.clearManualPrices(currency);
    if (!mounted || currency != _currency) return;
    setState(() {
      _fetching = false;
      if (fetched != null) {
        _prices = fetched;
      } else {
        _fetchFailed = true;
      }
    });
  }

  void _setCurrency(String currency) {
    setState(() {
      _currency = currency;
      _fetching = false;
      _loadPricesFor(currency);
    });
    _save();
  }

  void _clearAll() {
    for (final c in _controllers.values) {
      c.clear();
    }
    setState(() {});
    _save();
  }

  Future<void> _enterPricesManually() async {
    final t = AppLocalizations.of(context)!;
    final gold = TextEditingController(text: _prices != null ? _prices!.goldPerGram.toStringAsFixed(2) : '');
    final silver = TextEditingController(text: _prices != null ? _prices!.silverPerGram.toStringAsFixed(2) : '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.zakatEnterManually),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(gold, '${t.zakatGoldPerGram} ($_currency)'),
            SizedBox(height: 12.h),
            _dialogField(silver, '${t.zakatSilverPerGram} ($_currency)'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.save)),
        ],
      ),
    );
    final goldPrice = ZakatService.parseAmount(gold.text);
    final silverPrice = ZakatService.parseAmount(silver.text);
    gold.dispose();
    silver.dispose();
    if (saved != true || goldPrice <= 0 || silverPrice <= 0 || !mounted) return;
    final prices = MetalPrices(
      currency: _currency,
      goldPerGram: goldPrice,
      silverPerGram: silverPrice,
      asOf: DateTime.now(),
      isManual: true,
    );
    await _service.saveManualPrices(prices);
    if (mounted) {
      setState(() {
        _prices = prices;
        _fetchFailed = false;
      });
    }
  }

  Widget _dialogField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_amountFormatter],
      decoration: InputDecoration(labelText: label),
    );
  }

  static final _amountFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫٬ ]'));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    final money = _moneyFormat(languageCode);
    final grams = NumberFormat.decimalPattern(_intlLocale(languageCode));
    final prices = _prices;
    final result = prices == null ? null : ZakatService.calculate(_inputs, prices, _standard);

    final palette = _Palette(accent: accent, textColor: textColor, subColor: subColor, cardColor: cardColor, isDark: isDark);

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.zakatTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19.sp, color: textColor)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: t.zakatClearAll,
            icon: Icon(Iconsax.trash, color: accent),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: ReadableWidth(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, navBarClearance(context) + 24.h),
            children: [
              _Card(
                palette: palette,
                icon: Iconsax.money_4,
                title: t.zakatCurrency,
                child: DropdownButton<String>(
                  value: _currency,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: cardColor,
                  style: TextStyle(fontSize: 14.sp, color: textColor),
                  items: [
                    for (final code in ZakatService.currencies)
                      DropdownMenuItem(value: code, child: Text('$code  ${_symbol(code)}')),
                  ],
                  onChanged: (value) {
                    if (value != null && value != _currency) _setCurrency(value);
                  },
                ),
              ),
              SizedBox(height: 14.h),
              _Card(
                palette: palette,
                icon: Iconsax.wallet_money,
                title: t.zakatAssetsSection,
                child: Column(
                  children: [
                    _amountField(_Field.cash, t.zakatCash, _currency, palette),
                    _amountField(_Field.goldGrams, t.zakatGoldGrams, 'g', palette),
                    _amountField(_Field.silverGrams, t.zakatSilverGrams, 'g', palette),
                    _amountField(_Field.investments, t.zakatInvestments, _currency, palette),
                    _amountField(_Field.businessStock, t.zakatBusinessStock, _currency, palette),
                    _amountField(_Field.receivables, t.zakatReceivables, _currency, palette),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              _Card(
                palette: palette,
                icon: Iconsax.money_recive,
                title: t.zakatDeductionsSection,
                child: _amountField(_Field.debts, t.zakatDebts, _currency, palette),
              ),
              SizedBox(height: 14.h),
              _buildPricesCard(t, palette, money, languageCode),
              SizedBox(height: 14.h),
              _Card(
                palette: palette,
                icon: Iconsax.coin,
                title: t.zakatNisabSection,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _nisabOption(
                      NisabStandard.gold,
                      t.zakatNisabGold(grams.format(ZakatService.goldNisabGrams)),
                      result == null ? null : money.format(result.goldNisabValue),
                      palette,
                    ),
                    SizedBox(height: 8.h),
                    _nisabOption(
                      NisabStandard.silver,
                      t.zakatNisabSilver(grams.format(ZakatService.silverNisabGrams)),
                      result == null ? null : money.format(result.silverNisabValue),
                      palette,
                    ),
                    SizedBox(height: 10.h),
                    Text(t.zakatNisabNote, style: TextStyle(fontSize: 12.sp, height: 1.45, color: subColor)),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              _buildResultCard(t, palette, money, result),
              SizedBox(height: 14.h),
              _buildHowItWorks(t, palette, languageCode),
              SizedBox(height: 14.h),
              _Card(
                palette: palette,
                icon: Iconsax.info_circle,
                title: null,
                child: Text(t.zakatDisclaimer,
                    style: TextStyle(fontSize: 13.sp, height: 1.45, fontWeight: FontWeight.w600, color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// intl has no data for some locales' regional variants; the app only
  /// uses bare language codes, all of which intl supports.
  String _intlLocale(String languageCode) =>
      NumberFormat.localeExists(languageCode) ? languageCode : 'en';

  NumberFormat _moneyFormat(String languageCode) {
    return NumberFormat.currency(
      locale: _intlLocale(languageCode),
      name: _currency,
      symbol: '${_symbol(_currency)} ',
      decimalDigits: 2,
    );
  }

  String _symbol(String code) {
    try {
      return NumberFormat.simpleCurrency(name: code).currencySymbol;
    } catch (_) {
      return code;
    }
  }

  String _formatDate(DateTime date, String languageCode) {
    try {
      return DateFormat.yMMMd(languageCode).format(date);
    } catch (_) {
      return DateFormat.yMMMd('en').format(date);
    }
  }

  Widget _amountField(_Field field, String label, String unit, _Palette p) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextField(
        controller: _controllers[field],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_amountFormatter],
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          setState(() {});
          _save();
        },
        style: TextStyle(fontSize: 14.sp, color: p.textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13.sp, color: p.subColor),
          floatingLabelStyle: TextStyle(color: p.accent),
          hintText: '0',
          suffixText: unit,
          suffixStyle: TextStyle(fontSize: 12.sp, color: p.subColor),
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: p.textColor.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: p.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _nisabOption(NisabStandard standard, String label, String? value, _Palette p) {
    final selected = _standard == standard;
    return PressableTile(
      onTap: () {
        setState(() => _standard = standard);
        _save();
      },
      semanticLabel: label,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: selected ? p.accent.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(color: selected ? p.accent : p.textColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(selected ? Iconsax.tick_circle5 : Iconsax.record, color: selected ? p.accent : p.subColor, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: p.textColor)),
            ),
            if (value != null)
              Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: p.accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricesCard(AppLocalizations t, _Palette p, NumberFormat money, String languageCode) {
    final prices = _prices;
    return _Card(
      palette: p,
      icon: Iconsax.coin_1,
      title: t.zakatPricesSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prices != null) ...[
            _row(t.zakatGoldPerGram, money.format(prices.goldPerGram), p),
            _row(t.zakatSilverPerGram, money.format(prices.silverPerGram), p),
            SizedBox(height: 4.h),
            Text(
              '${t.zakatPriceAsOf(_formatDate(prices.asOf, languageCode))} · '
              '${prices.isManual ? t.zakatPriceManual : t.zakatPriceLive}',
              style: TextStyle(fontSize: 12.sp, color: p.subColor),
            ),
          ] else if (!_fetching)
            Text(t.zakatNoPrice, style: TextStyle(fontSize: 13.sp, color: p.textColor)),
          if (_fetching)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Center(
                child: SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
                ),
              ),
            ),
          if (_fetchFailed) ...[
            SizedBox(height: 6.h),
            Text(t.zakatPriceFetchFailed, style: TextStyle(fontSize: 12.sp, height: 1.4, color: p.subColor)),
          ],
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: [
              TextButton.icon(
                onPressed: _fetching ? null : () => _refreshPrices(),
                icon: Icon(Iconsax.refresh, size: 16.sp, color: p.accent),
                label: Text(t.zakatRefreshPrice, style: TextStyle(color: p.accent, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: _enterPricesManually,
                icon: Icon(Iconsax.edit_2, size: 16.sp, color: p.accent),
                label: Text(t.zakatEnterManually, style: TextStyle(color: p.accent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(AppLocalizations t, _Palette p, NumberFormat money, ZakatResult? r) {
    if (r == null) {
      return _Card(
        palette: p,
        icon: Iconsax.calculator,
        title: t.zakatResultSection,
        child: Text(t.zakatNoPrice, style: TextStyle(fontSize: 13.sp, color: p.subColor)),
      );
    }
    final divider = Divider(height: 16.h, color: p.textColor.withValues(alpha: 0.12));
    return _Card(
      palette: p,
      icon: Iconsax.calculator,
      title: t.zakatResultSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(t.zakatCash, money.format(r.cash), p),
          _row(t.zakatGoldValue, money.format(r.goldValue), p),
          _row(t.zakatSilverValue, money.format(r.silverValue), p),
          _row(t.zakatInvestments, money.format(r.investments), p),
          _row(t.zakatBusinessStock, money.format(r.businessStock), p),
          _row(t.zakatReceivables, money.format(r.receivables), p),
          divider,
          _row(t.zakatTotalAssets, money.format(r.totalAssets), p, bold: true),
          _row(t.zakatLessDebts, '− ${money.format(r.debts)}', p),
          divider,
          _row(t.zakatZakatableWealth, money.format(r.zakatableWealth), p, bold: true),
          _row(t.zakatNisabValue, money.format(r.nisabValue), p),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: r.isDue ? p.accent.withValues(alpha: 0.14) : p.textColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: r.isDue ? p.accent : p.textColor.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Text(
                  r.isDue ? t.zakatIsDue : t.zakatNotDue,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: r.isDue ? p.accent : p.subColor,
                  ),
                ),
                if (r.isDue) ...[
                  SizedBox(height: 6.h),
                  Text(t.zakatAmountDue, style: TextStyle(fontSize: 12.sp, color: p.subColor)),
                  SizedBox(height: 2.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      money.format(r.zakatDue),
                      style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800, color: p.textColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(AppLocalizations t, _Palette p, String languageCode) {
    final verse = ShareContent.fromQuran(zakatRecipientsVerse, languageCode);
    Widget point(String text, String? reference) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: TextStyle(fontSize: 13.sp, height: 1.5, color: p.textColor)),
              if (reference != null) ...[
                SizedBox(height: 3.h),
                Text(reference, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: p.accent)),
              ],
            ],
          ),
        );

    // A Material (not a decorated Container) so the tile's ink has a surface.
    return Material(
      color: p.cardColor,
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Iconsax.book_1, color: p.accent, size: 18.sp),
          title: Text(t.zakatHowItWorks,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: p.textColor)),
          iconColor: p.accent,
          collapsedIconColor: p.textColor,
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            point(t.zakatHowNisab, '$zakatSilverNisabReference; $zakatRateReference'),
            point(t.zakatHowRate, zakatRateReference),
            point(t.zakatHowRecipients, null),
            Text(
              verse.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.start,
              style: ScriptureText.arabic(fontSize: 18.sp, color: p.textColor),
            ),
            if (verse.translation.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                verse.translation,
                textDirection: verse.translationIsUrdu ? TextDirection.rtl : null,
                style: verse.translationIsUrdu
                    ? ScriptureText.urdu(fontSize: 13.sp, color: p.subColor)
                    : TextStyle(fontSize: 13.sp, height: 1.5, color: p.subColor),
              ),
            ],
            SizedBox(height: 3.h),
            Text(verse.reference, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: p.accent)),
            SizedBox(height: 12.h),
            point(t.zakatHowDebts, null),
            point(t.zakatHowJewellery, null),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, _Palette p, {bool bold = false}) {
    final weight = bold ? FontWeight.w700 : FontWeight.w500;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: weight, color: p.textColor))),
          SizedBox(width: 10.w),
          Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: weight, color: p.textColor)),
        ],
      ),
    );
  }
}

class _Palette {
  final Color accent;
  final Color textColor;
  final Color subColor;
  final Color cardColor;
  final bool isDark;

  const _Palette({
    required this.accent,
    required this.textColor,
    required this.subColor,
    required this.cardColor,
    required this.isDark,
  });
}

class _Card extends StatelessWidget {
  final _Palette palette;
  final IconData icon;
  final String? title;
  final Widget child;

  const _Card({required this.palette, required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: palette.cardColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: title == null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: palette.accent, size: 18.sp),
                SizedBox(width: 10.w),
                Expanded(child: child),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, color: palette.accent, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: palette.textColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                child,
              ],
            ),
    );
  }
}
