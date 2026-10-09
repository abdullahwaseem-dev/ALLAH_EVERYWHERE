import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';

/// Picks the calculation method that the authorities / most mosques in a
/// country use. Isha is where methods differ most (Umm al-Qura: a fixed
/// 90 min after Maghrib; Karachi: 18°; MWL: 17°; ISNA: 15°), so one global
/// default gave a wrong Isha almost everywhere. These are defaults only -
/// local mosques can differ, and the user can always pick a method in
/// Settings, which overrides this.
CalculationMethod methodForCountry(String? isoCountryCode) {
  switch (isoCountryCode?.toUpperCase()) {
    case 'SA':
    case 'YE':
      return CalculationMethod.umm_al_qura;
    case 'AE':
      return CalculationMethod.dubai;
    case 'QA':
    case 'BH':
    case 'OM':
      return CalculationMethod.qatar;
    case 'KW':
      return CalculationMethod.kuwait;
    case 'PK':
    case 'IN':
    case 'BD':
    case 'AF':
    case 'NP':
    case 'LK':
      return CalculationMethod.karachi;
    case 'US':
    case 'CA':
      return CalculationMethod.north_america;
    case 'EG':
    case 'SD':
    case 'LY':
    case 'SY':
    case 'LB':
    case 'IQ':
    case 'JO':
    case 'PS':
      return CalculationMethod.egyptian;
    case 'SG':
    case 'MY':
    case 'ID':
    case 'BN':
      return CalculationMethod.singapore;
    case 'TR':
      return CalculationMethod.turkey;
    case 'IR':
      return CalculationMethod.tehran;
    default:
      return CalculationMethod.muslim_world_league;
  }
}

/// Parameters for [date]. The single source for both the on-screen times
/// and the scheduled Adhan notifications, so the two can never disagree.
CalculationParameters prayerParameters(CalculationMethod method, Madhab madhab, DateTime date) {
  final params = method.getParameters();
  params.madhab = madhab;
  // Umm al-Qura moves Isha to 120 min after Maghrib during Ramadan; the
  // adhan package only knows the normal 90. The tabular Hijri date can be a
  // day off from the local moon sighting at the start/end of Ramadan.
  if (method == CalculationMethod.umm_al_qura && HijriCalendar.fromDate(date).hMonth == 9) {
    params.ishaInterval = 120;
  }
  return params;
}
