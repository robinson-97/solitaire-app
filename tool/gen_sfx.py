"""Synthesises Hopstone's soft sound effects (no recordings, nothing to license).
Run: python3 tool/gen_sfx.py   ->  assets/sfx/*.wav
"""
import wave
import numpy as np

SR = 44100
rng = np.random.default_rng(7)


def t_axis(sec):
    return np.arange(int(SR * sec)) / SR


def lowpass(x, k):
    """One-pole low-pass; smaller k = softer."""
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def env(n, attack=0.004, decay=40.0):
    t = np.arange(n) / SR
    a = np.minimum(1.0, t / attack)
    return a * np.exp(-t * decay)


def wood(freq, sec=0.18, decay=48.0, amp=1.0):
    t = t_axis(sec)
    tone = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 2.01 * t) + 0.12 * np.sin(2 * np.pi * freq * 3.2 * t)
    click = rng.standard_normal(len(t)) * np.exp(-t * 400) * 0.25
    return amp * (tone * env(len(t), decay=decay) + click)


def bell(freq, sec=1.3, amp=1.0, decay=3.2):
    t = t_axis(sec)
    tone = (np.sin(2 * np.pi * freq * t)
            + 0.45 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t * 4)
            + 0.18 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t * 7))
    return amp * tone * env(len(t), attack=0.006, decay=decay)


def glide(f0, f1, sec, amp=1.0):
    t = t_axis(sec)
    f = f0 + (f1 - f0) * (t / sec)
    phase = 2 * np.pi * np.cumsum(f) / SR
    shape = np.sin(np.pi * t / sec) ** 2
    return amp * np.sin(phase) * shape


def place(buf, sig, at):
    i = int(SR * at)
    end = min(len(buf), i + len(sig))
    buf[i:end] += sig[: end - i]


def save(name, sig, peak=0.55, soft=0.35):
    sig = lowpass(sig, soft)
    sig = sig / max(1e-9, np.max(np.abs(sig))) * peak
    fade = int(SR * 0.01)
    sig[-fade:] *= np.linspace(1, 0, fade)
    with wave.open(f"assets/sfx/{name}.wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((sig * 32767).astype(np.int16).tobytes())


def buf(sec):
    return np.zeros(int(SR * sec))


# pick up a peg: a soft wooden tick
b = buf(0.2)
place(b, wood(660, 0.18, 55), 0)
save("select", b, 0.5)

# jump: airy rise, then a wooden landing in time with the animation (~0.5 s)
b = buf(0.8)
place(b, glide(260, 700, 0.42, 0.35), 0.03)
air = rng.standard_normal(int(SR * 0.4)) * np.sin(np.linspace(0, np.pi, int(SR * 0.4))) ** 2 * 0.06
place(b, lowpass(air, 0.08), 0.05)
place(b, wood(230, 0.3, 28, 1.0), 0.50)
place(b, wood(150, 0.3, 30, 0.6), 0.50)
save("jump", b, 0.6)

# not allowed: two low, muted thuds
b = buf(0.4)
place(b, wood(150, 0.2, 40), 0.0)
place(b, wood(130, 0.2, 40, 0.8), 0.11)
save("invalid", b, 0.5, 0.25)

# undo: a gentle falling glide
b = buf(0.3)
place(b, glide(640, 360, 0.22, 0.8), 0.0)
place(b, wood(420, 0.12, 60, 0.3), 0.18)
save("undo", b, 0.45)

# level cleared: bright bell arpeggio
b = buf(2.0)
for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
    place(b, bell(f, 1.4, 1.0 - i * 0.08), i * 0.13)
place(b, bell(1318.5, 1.2, 0.5), 0.55)
save("win", b, 0.55, 0.5)

# not cleared: two soft falling tones
b = buf(1.0)
place(b, bell(392.0, 0.8, 0.8, 4.5), 0.0)
place(b, bell(329.63, 0.9, 0.8, 4.0), 0.2)
save("end", b, 0.45, 0.4)

# unlock: sparkle run into a chord
b = buf(1.8)
for i, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0, 2637.0]):
    place(b, bell(f, 0.7, 0.55, 6.0), i * 0.07)
for f in [783.99, 987.77, 1174.7]:
    place(b, bell(f, 1.4, 0.7), 0.4)
save("unlock", b, 0.5, 0.5)
print("ok")
