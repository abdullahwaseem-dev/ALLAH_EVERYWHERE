import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:just_audio/just_audio.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/data/adhan_sounds.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/adhan_sound_service.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/widgets/layout_helpers.dart';
import 'package:allah_everywhere/widgets/pressable_tile.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Settings > Adhan Sound: the sound for Dhuhr-Isha, a separate one for
/// Fajr, and per prayer whether it's an adhan, a beep, silent or off. Any
/// change re-schedules the prayer notifications.
class AdhanSoundSettingsScreen extends StatefulWidget {
  const AdhanSoundSettingsScreen({super.key});

  @override
  State<AdhanSoundSettingsScreen> createState() => _AdhanSoundSettingsScreenState();
}

class _AdhanSoundSettingsScreenState extends State<AdhanSoundSettingsScreen> {
  // Created on first preview, so opening the screen never touches audio.
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerSub;
  String? _playingId;

  late AdhanSound _sound = AdhanSoundService.sound;
  late AdhanSound _fajrSound = AdhanSoundService.fajrSound;
  late final Map<String, PrayerAlert> _alerts = {for (final p in alertPrayers) p: AdhanSoundService.alertFor(p)};

  @override
  void dispose() {
    _playerSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _reschedule() async {
    if (Get.isRegistered<PrayerTimesController>()) {
      await Get.find<PrayerTimesController>().rescheduleNotifications();
    }
  }

  Future<void> _pick(AdhanSound sound, {required bool fajr}) async {
    setState(() => fajr ? _fajrSound = sound : _sound = sound);
    await (fajr ? AdhanSoundService.setFajrSound(sound) : AdhanSoundService.setSound(sound));
    await _reschedule();
  }

  Future<void> _setAlert(String prayer, PrayerAlert alert) async {
    setState(() => _alerts[prayer] = alert);
    await AdhanSoundService.setAlert(prayer, alert);
    await _reschedule();
  }

  Future<void> _togglePreview(AdhanSound sound) async {
    final asset = sound.preview;
    if (asset == null) return;
    final player = _player ??= AudioPlayer();
    _playerSub ??= player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _playingId = null);
      }
    });
    if (_playingId == sound.id) {
      await player.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    try {
      // Don't play over a Quran recitation.
      try {
        await QuranAudioService.handler.pause();
      } catch (_) {}
      setState(() => _playingId = sound.id);
      await player.setAsset(asset);
      unawaited(player.play());
    } catch (e) {
      VoidLogger.error('Could not play adhan preview $asset', e);
      if (mounted) setState(() => _playingId = null);
    }
  }

  String _label(AppLocalizations t, AdhanSound s) => switch (s.id) {
        'default' => t.soundDefaultAdhan,
        'gentle' => t.soundGentle,
        'makkah' => t.soundMakkah,
        'madinah' => t.soundMadinah,
        'alafasy' => t.soundAlafasy,
        'makkah_fajr' => t.soundMakkahFajr,
        'madinah_fajr' => t.soundMadinahFajr,
        'alafasy_fajr' => t.soundAlafasyFajr,
        'beep' => t.soundBeep,
        'silent' => t.soundSilent,
        _ => s.id,
      };

  String? _subtitle(AppLocalizations t, AdhanSound s, {required bool fajr}) {
    if (!s.available) return t.soundNotAdded;
    if (s.id == 'gentle') return t.soundGentleSubtitle;
    if (s.id == 'beep') return t.soundBeepSubtitle;
    if (fajr && s.id == 'default') return t.soundDefaultFajrSubtitle;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    final subColor = isDark ? VoidColors.textDarkSecondary : Colors.grey.shade600;
    final cardColor = isDark ? VoidColors.cardDark : VoidColors.cardLight;

    Widget card(IconData icon, String title, List<Widget> children, {String? note}) => Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18.r)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(title,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor)),
                  ),
                ],
              ),
              if (note != null) ...[
                SizedBox(height: 4.h),
                Text(note, style: TextStyle(fontSize: 11.5.sp, height: 1.4, color: subColor)),
              ],
              SizedBox(height: 6.h),
              ...children,
            ],
          ),
        );

    Widget soundRow(AdhanSound s, {required bool fajr}) {
      final selected = (fajr ? _fajrSound : _sound).id == s.id;
      final enabled = s.available;
      final subtitle = _subtitle(t, s, fajr: fajr);
      final canPreview = enabled && s.preview != null;
      final playing = _playingId == s.id;
      return PressableTile(
        onTap: enabled && !selected ? () => _pick(s, fajr: fajr) : null,
        semanticLabel: _label(t, s),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Row(
            children: [
              Icon(
                selected ? Iconsax.tick_circle5 : Iconsax.record,
                size: 20.sp,
                color: !enabled ? subColor.withValues(alpha: 0.4) : (selected ? accent : subColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(t, s),
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: enabled ? textColor : textColor.withValues(alpha: 0.4),
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(fontSize: 11.5.sp, color: subColor)),
                  ],
                ),
              ),
              if (canPreview)
                IconButton(
                  tooltip: playing ? t.previewStop : t.previewPlay,
                  icon: Icon(playing ? Iconsax.stop_circle : Iconsax.play_circle, color: accent, size: 24.sp),
                  onPressed: () => _togglePreview(s),
                ),
            ],
          ),
        ),
      );
    }

    String prayerName(String p) => switch (p) {
          'Fajr' => t.fajr,
          'Dhuhr' => t.dhuhr,
          'Asr' => t.asr,
          'Maghrib' => t.maghrib,
          _ => t.isha,
        };

    String alertLabel(PrayerAlert a) => switch (a) {
          PrayerAlert.adhan => t.alertAdhan,
          PrayerAlert.beep => t.alertBeep,
          PrayerAlert.silent => t.alertSilent,
          PrayerAlert.off => t.alertOff,
        };

    Widget alertRow(String prayer) => Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prayerName(prayer),
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: textColor)),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  for (final a in PrayerAlert.values)
                    ChoiceChip(
                      label: Text(alertLabel(a)),
                      selected: _alerts[prayer] == a,
                      onSelected: (_) => _setAlert(prayer, a),
                      selectedColor: accent,
                      backgroundColor: cardColor,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12.sp,
                        color: _alerts[prayer] == a ? Colors.white : textColor,
                      ),
                      side: BorderSide(color: accent.withValues(alpha: 0.35)),
                    ),
                ],
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: isDark ? VoidColors.bgDark : VoidColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: VoidBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.adhanSound, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: textColor)),
        centerTitle: true,
      ),
      body: ReadableWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, navBarClearance(context) + 24.h),
          children: [
            card(Iconsax.volume_high, t.adhanSoundPrayers, [
              for (final s in prayerSounds) soundRow(s, fajr: false),
            ]),
            card(Iconsax.sun_fog, t.adhanSoundFajr, note: t.adhanFajrNote, [
              for (final s in fajrSounds) soundRow(s, fajr: true),
            ]),
            card(Iconsax.notification, t.adhanPerPrayer, [
              for (final p in alertPrayers) alertRow(p),
            ]),
          ],
        ),
      ),
    );
  }
}
