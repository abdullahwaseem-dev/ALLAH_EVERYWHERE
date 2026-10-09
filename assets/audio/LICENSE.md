# Audio asset licensing

## adhan.ogg

- Source: https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg
- License: CC0 1.0 Universal (Public Domain Dedication) — no attribution legally required.
- Uploaded by Wikimedia Commons user Adam-synagda, April 2022.
- Duration: 2:34. Used as-is on Android (raw resource, no duration limit for notification sounds).

## ios/Runner/adhan.caf

- Derived from the same `adhan.ogg` above (CC0), so the same license applies.
- iOS custom notification sounds must be `.caf`/`.aiff`/`.wav` and at most 30 seconds, so this is
  the opening two takbir phrases (0.9s–30.6s of the original, 29.7s), with a short fade-out,
  loudness-normalised and encoded as mono IMA4 CAF. Recreate with:
  `ffmpeg -ss 0.9 -to 30.6 -i adhan.ogg -af "afade=t=in:d=0.15,afade=t=out:st=28.3:d=1.4,loudnorm=I=-16:TP=-1.5" -ar 44100 -ac 1 adhan.wav && afconvert -f caff -d ima4 adhan.wav adhan.caf`

## Derived from adhan.ogg (CC0, same license)

- `assets/audio/preview_adhan_default.m4a` — the Settings preview: `ios/Runner/adhan.caf` re-encoded as AAC
  (`afconvert -f m4af -d aac ios/Runner/adhan.caf assets/audio/preview_adhan_default.m4a`).
- `android/app/src/main/res/raw/adhan_gentle.wav`, `ios/Runner/adhan_gentle.caf`,
  `assets/audio/preview_adhan_gentle.m4a` — the "gentle" Fajr alert: the opening takbir only (0–16.9s of
  `adhan.caf`), 10 dB quieter, 1.2s fade-out, mono 22.05 kHz. Recreate with `tool/make_gentle_adhan.py`
  (the commands are in its header).

## Adhan recordings still to be added

These sounds are listed in the app (`lib/data/adhan_sounds.dart`, `available: false`) but have no audio yet.
For each one, add a recording you have the rights to use, run `tool/prepare_adhan_audio.sh <id> <file>`,
and fill in its entry below before setting `available: true`.

| id | Files the script creates |
|---|---|
| `makkah` | `res/raw/adhan_makkah.ogg`, `ios/Runner/adhan_makkah.caf`, `assets/audio/preview_adhan_makkah.m4a` |
| `madinah` | `res/raw/adhan_madinah.ogg`, `ios/Runner/adhan_madinah.caf`, `assets/audio/preview_adhan_madinah.m4a` |
| `alafasy` | `res/raw/adhan_alafasy.ogg`, `ios/Runner/adhan_alafasy.caf`, `assets/audio/preview_adhan_alafasy.m4a` |
| `makkah_fajr` | `res/raw/adhan_makkah_fajr.ogg`, `ios/Runner/adhan_makkah_fajr.caf`, `assets/audio/preview_adhan_makkah_fajr.m4a` |
| `madinah_fajr` | `res/raw/adhan_madinah_fajr.ogg`, `ios/Runner/adhan_madinah_fajr.caf`, `assets/audio/preview_adhan_madinah_fajr.m4a` |
| `alafasy_fajr` | `res/raw/adhan_alafasy_fajr.ogg`, `ios/Runner/adhan_alafasy_fajr.caf`, `assets/audio/preview_adhan_alafasy_fajr.m4a` |

The `_fajr` recordings must be the Fajr adhan (with "as-salatu khayrun min an-nawm").

### Template for each recording (copy, fill in, keep)

```
## adhan_<id>

- Reciter / muezzin:
- Source (URL or where it was obtained):
- License or written permission (attach or link):
- Attribution required? (exact wording if so):
- Original duration:
- iOS/preview clip: 29.5s starting at <start>s (tool/prepare_adhan_audio.sh)
```
