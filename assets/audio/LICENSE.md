# Audio asset licensing

## adhan.ogg

- Source: https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg
- License: CC0 1.0 Universal (Public Domain Dedication) — no attribution legally required.
- Uploaded by Wikimedia Commons user Adam-synagda, April 2022.
- Duration: 2:34. Used as-is on Android (raw resource, no duration limit for notification sounds).
  iOS custom notification sounds require `.caf`/`.wav` format and a maximum of 30 seconds — this
  file has not been converted/trimmed (no audio tooling was available in the environment that added
  it), so iOS currently falls back to the default system notification sound for prayer alerts. To
  finish this: trim to a ~15-30s excerpt and convert to `.caf`, then add it to
  `ios/Runner/Resources/`.
