// CONTENT REVIEW REQUIRED: verify against source before release

import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/islamic_calendar_service.dart';

// Sources for the Islamic calendar's events. Only references live here; the
// descriptions are short localized paraphrases in lib/l10n/*.arb (keys
// calEvent<Name>/calEvent<Name>Desc), never quoted hadith.

/// Book + number for each event (sunnah.com numbering for hadith).
const Map<IslamicEventType, String> islamicEventSources = {
  IslamicEventType.newYear: 'Sahih al-Bukhari 3934',
  IslamicEventType.tasua: 'Sahih Muslim 1134',
  IslamicEventType.ashura: 'Sahih Muslim 1162; Sahih Muslim 1134',
  IslamicEventType.mawlid: 'Sahih Muslim 1162 (fasting on Monday, the day he ﷺ was born)',
  IslamicEventType.israMiraj: 'Quran 17:1',
  IslamicEventType.midShaban: 'Sunan Ibn Majah 1390 (graded hasan by al-Albani; da\'if by Shu\'ayb al-Arna\'ut and Zubair Ali Zai)',
  IslamicEventType.ramadanStart: 'Quran 2:185; Sahih al-Bukhari 1900',
  IslamicEventType.lastTenNights: 'Sahih al-Bukhari 2017; Quran 97',
  IslamicEventType.oddNight: 'Sahih al-Bukhari 2017',
  IslamicEventType.eidFitr: 'Sahih al-Bukhari 1990; Sahih Muslim 1137',
  IslamicEventType.shawwalSix: 'Sahih Muslim 1164',
  IslamicEventType.arafah: 'Sahih Muslim 1162',
  IslamicEventType.eidAdha: 'Sahih al-Bukhari 1990; Sahih Muslim 1137',
  IslamicEventType.tashreeq: 'Sahih Muslim 1141; Sahih al-Bukhari 1997',
  IslamicEventType.mondayThursday: "Jami' at-Tirmidhi 747; Sahih Muslim 1162",
  IslamicEventType.whiteDays: "Jami' at-Tirmidhi 761; Sunan an-Nasa'i 2422",
};

String islamicEventName(AppLocalizations t, IslamicEventType type) {
  switch (type) {
    case IslamicEventType.newYear:
      return t.calEventNewYear;
    case IslamicEventType.tasua:
      return t.calEventTasua;
    case IslamicEventType.ashura:
      return t.calEventAshura;
    case IslamicEventType.mawlid:
      return t.calEventMawlid;
    case IslamicEventType.israMiraj:
      return t.calEventIsraMiraj;
    case IslamicEventType.midShaban:
      return t.calEventMidShaban;
    case IslamicEventType.ramadanStart:
      return t.calEventRamadanStart;
    case IslamicEventType.lastTenNights:
      return t.calEventLastTenNights;
    case IslamicEventType.oddNight:
      return t.calEventOddNight;
    case IslamicEventType.eidFitr:
      return t.calEventEidFitr;
    case IslamicEventType.shawwalSix:
      return t.calEventShawwalSix;
    case IslamicEventType.arafah:
      return t.calEventArafah;
    case IslamicEventType.eidAdha:
      return t.calEventEidAdha;
    case IslamicEventType.tashreeq:
      return t.calEventTashreeq;
    case IslamicEventType.mondayThursday:
      return t.calEventMondayThursday;
    case IslamicEventType.whiteDays:
      return t.calEventWhiteDays;
  }
}

String islamicEventDescription(AppLocalizations t, IslamicEventType type) {
  switch (type) {
    case IslamicEventType.newYear:
      return t.calEventNewYearDesc;
    case IslamicEventType.tasua:
      return t.calEventTasuaDesc;
    case IslamicEventType.ashura:
      return t.calEventAshuraDesc;
    case IslamicEventType.mawlid:
      return t.calEventMawlidDesc;
    case IslamicEventType.israMiraj:
      return t.calEventIsraMirajDesc;
    case IslamicEventType.midShaban:
      return t.calEventMidShabanDesc;
    case IslamicEventType.ramadanStart:
      return t.calEventRamadanStartDesc;
    case IslamicEventType.lastTenNights:
      return t.calEventLastTenNightsDesc;
    case IslamicEventType.oddNight:
      return t.calEventOddNightDesc;
    case IslamicEventType.eidFitr:
      return t.calEventEidFitrDesc;
    case IslamicEventType.shawwalSix:
      return t.calEventShawwalSixDesc;
    case IslamicEventType.arafah:
      return t.calEventArafahDesc;
    case IslamicEventType.eidAdha:
      return t.calEventEidAdhaDesc;
    case IslamicEventType.tashreeq:
      return t.calEventTashreeqDesc;
    case IslamicEventType.mondayThursday:
      return t.calEventMondayThursdayDesc;
    case IslamicEventType.whiteDays:
      return t.calEventWhiteDaysDesc;
  }
}

/// "26 Rabi' al-Thani 1448 AH" in the app language.
String formatHijriDate(AppLocalizations t, HijriDate h) =>
    '${h.day} ${t.hijriMonthName('${h.month}')} ${t.hijriYear('${h.year}')}';
