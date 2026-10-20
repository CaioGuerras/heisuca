# Gera o "tum" da abertura do CGFLIX (procedural, sem amostras de terceiros).
import math, struct, sys, wave
rate, dur = 22050, 0.85
n = int(rate * dur)
out = []
phase1 = phase2 = phase3 = 0.0
for i in range(n):
    t = i / rate
    f = 58 + 92 * math.exp(-t * 9)          # queda de tom 150 Hz -> 58 Hz
    phase1 += 2 * math.pi * f / rate
    phase2 += 2 * math.pi * f * 2.01 / rate
    phase3 += 2 * math.pi * 523.25 / rate   # brilho suave (dó) bem baixinho
    attack = min(1.0, t / 0.006)
    body = math.sin(phase1) * math.exp(-t * 4.2)
    harm = 0.35 * math.sin(phase2) * math.exp(-t * 9)
    shine = 0.06 * math.sin(phase3) * math.exp(-t * 5) * min(1.0, t / 0.08)
    v = attack * (body + harm + shine) * 0.82
    fade = min(1.0, (dur - t) / 0.08)
    out.append(int(max(-1, min(1, v * fade)) * 32767))
with wave.open(sys.argv[1], 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
    w.writeframes(b''.join(struct.pack('<h', s) for s in out))
