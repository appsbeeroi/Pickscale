import math
import os
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "Pickscale", "Assets", "Audio")


def write_wav(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    peak = max((abs(s) for s in samples), default=1.0) or 1.0
    norm = 0.92 / peak
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s * norm)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(bytes(frames))
    print("wrote", path, len(samples), "samples")


def env(i, total, attack=0.01, release=0.2):
    a = int(total * attack)
    r = int(total * release)
    if i < a:
        return i / max(1, a)
    if i > total - r:
        return max(0.0, (total - i) / max(1, r))
    return 1.0


def tone(freq, dur, vol=0.5, attack=0.01, release=0.2, harmonics=(1.0,)):
    total = int(SAMPLE_RATE * dur)
    out = []
    for i in range(total):
        t = i / SAMPLE_RATE
        val = 0.0
        for idx, amp in enumerate(harmonics, start=1):
            val += amp * math.sin(2 * math.pi * freq * idx * t)
        out.append(val * vol * env(i, total, attack, release))
    return out


def mix(*layers):
    length = max(len(l) for l in layers)
    out = [0.0] * length
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    return out


def sequence(notes):
    out = []
    for freq, dur, vol in notes:
        out += tone(freq, dur, vol=vol, attack=0.02, release=0.25, harmonics=(1.0, 0.35, 0.12))
    return out


def note(n):
    return 440.0 * (2 ** ((n - 69) / 12))


def build_music():
    # Gentle pastoral loop in C major, soft pad + arpeggio, ~8s, loop-friendly.
    chords = [
        [note(60), note(64), note(67)],
        [note(57), note(60), note(64)],
        [note(65), note(69), note(72)],
        [note(55), note(59), note(62)],
    ]
    beat = 2.0
    pad_layer = []
    for chord in chords:
        chord_tones = [tone(f, beat, vol=0.16, attack=0.25, release=0.4, harmonics=(1.0, 0.25)) for f in chord]
        pad_layer += mix(*chord_tones)

    arp = []
    for chord in chords:
        step = beat / 4
        for k in range(4):
            f = chord[k % len(chord)] * 2
            arp += tone(f, step, vol=0.10, attack=0.01, release=0.5, harmonics=(1.0, 0.2))

    length = min(len(pad_layer), len(arp))
    return mix(pad_layer[:length], arp[:length])


def build_tap():
    return tone(880, 0.08, vol=0.5, attack=0.005, release=0.6, harmonics=(1.0, 0.3))


def build_place():
    low = tone(220, 0.12, vol=0.5, attack=0.005, release=0.7, harmonics=(1.0, 0.4, 0.2))
    click = tone(140, 0.06, vol=0.3, attack=0.002, release=0.8)
    length = max(len(low), len(click))
    low += [0.0] * (length - len(low))
    click += [0.0] * (length - len(click))
    return mix(low, click)


def build_weigh():
    out = []
    total = int(SAMPLE_RATE * 0.4)
    for i in range(total):
        t = i / SAMPLE_RATE
        freq = 500 + 220 * math.sin(2 * math.pi * 3 * t)
        out.append(math.sin(2 * math.pi * freq * t) * 0.4 * env(i, total, 0.02, 0.4))
    return out


def build_correct():
    return sequence([
        (note(72), 0.12, 0.45),
        (note(76), 0.12, 0.45),
        (note(79), 0.12, 0.45),
        (note(84), 0.28, 0.5),
    ])


def build_wrong():
    return sequence([
        (note(64), 0.16, 0.4),
        (note(60), 0.16, 0.4),
        (note(55), 0.30, 0.42),
    ])


def build_star():
    return sequence([
        (note(84), 0.08, 0.4),
        (note(88), 0.08, 0.4),
        (note(91), 0.18, 0.45),
    ])


def main():
    write_wav("music_loop.wav", build_music())
    write_wav("sfx_tap.wav", build_tap())
    write_wav("sfx_place.wav", build_place())
    write_wav("sfx_weigh.wav", build_weigh())
    write_wav("sfx_correct.wav", build_correct())
    write_wav("sfx_wrong.wav", build_wrong())
    write_wav("sfx_star.wav", build_star())


if __name__ == "__main__":
    main()
