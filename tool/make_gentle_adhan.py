"""Builds the "gentle" Fajr alert from the CC0 adhan already in the app.

Input: an uncompressed AIFF of ios/Runner/adhan.caf, made with
    afconvert -f AIFF -d BEI16@44100 ios/Runner/adhan.caf adhan_30s.aiff
Output: a plain 16-bit PCM mono WAV at 22.05 kHz: the opening takbir only
(0-16.9 s), 10 dB quieter, with a 1.2 s fade-out.

    python3 tool/make_gentle_adhan.py adhan_30s.aiff android/app/src/main/res/raw/adhan_gentle.wav

Then, for iOS and the in-app preview:
    afconvert -f caff -d ima4 android/app/src/main/res/raw/adhan_gentle.wav ios/Runner/adhan_gentle.caf
    afconvert -f m4af -d aac android/app/src/main/res/raw/adhan_gentle.wav assets/audio/preview_adhan_gentle.m4a

Only the standard library is used (no ffmpeg needed).
"""
import array
import sys
import wave
import warnings

with warnings.catch_warnings():
    warnings.simplefilter('ignore', DeprecationWarning)
    import aifc

END_SECONDS = 16.9  # the first phrase ends here (silence from ~16.75 s)
FADE_SECONDS = 1.2
GAIN = 10 ** (-10 / 20)  # -10 dB

src, dst = sys.argv[1], sys.argv[2]
with aifc.open(src) as f:
    assert f.getnchannels() == 1 and f.getsampwidth() == 2, 'expected mono 16-bit AIFF'
    rate = f.getframerate()
    samples = array.array('h', f.readframes(f.getnframes()))
samples.byteswap()  # AIFF is big-endian

end = int(END_SECONDS * rate)
fade = int(FADE_SECONDS * rate)
out = []
for i in range(0, end - 1, 2):  # 44.1 -> 22.05 kHz: average sample pairs
    v = (samples[i] + samples[i + 1]) / 2 * GAIN
    remaining = end - i
    if remaining < fade:
        v *= remaining / fade
    out.append(int(max(-32768, min(32767, round(v)))))

with wave.open(dst, 'wb') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(rate // 2)
    w.writeframes(array.array('h', out).tobytes())
print(f'{dst}: {len(out) / (rate // 2):.2f} s')
