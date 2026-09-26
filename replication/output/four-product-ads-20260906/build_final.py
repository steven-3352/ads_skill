#!/usr/bin/env python3
from pathlib import Path
import subprocess
import wave

import numpy as np


ROOT = Path(__file__).resolve().parent
VISUALS = ROOT / "visuals"
FINAL = ROOT / "final"
AUDIO = ROOT / "audio"
FINAL.mkdir(parents=True, exist_ok=True)
AUDIO.mkdir(parents=True, exist_ok=True)

SAMPLE_RATE = 48000
DURATION = 15.0


def synth_bed(code, root_note):
    total = int(SAMPLE_RATE * DURATION)
    t = np.arange(total) / SAMPLE_RATE
    audio = np.zeros(total, dtype=np.float64)

    chord_steps = [0, 5, 3, 7]
    chord_length = 3.75
    for index, step in enumerate(chord_steps):
        start = int(index * chord_length * SAMPLE_RATE)
        end = int((index + 1) * chord_length * SAMPLE_RATE)
        local_t = np.arange(end - start) / SAMPLE_RATE
        base = root_note * (2 ** (step / 12))
        pad = sum(np.sin(2 * np.pi * base * ratio * local_t) for ratio in (1, 1.25, 1.5)) / 3
        envelope = np.minimum(local_t / 0.35, 1) * np.minimum((chord_length - local_t) / 0.45, 1)
        audio[start:end] += 0.075 * pad * np.clip(envelope, 0, 1)

    beat_times = np.arange(0, DURATION, 0.5)
    for beat_index, beat in enumerate(beat_times):
        start = int(beat * SAMPLE_RATE)
        length = int(0.12 * SAMPLE_RATE)
        local_t = np.arange(length) / SAMPLE_RATE
        frequency = 95 if beat_index % 2 == 0 else 145
        click = np.sin(2 * np.pi * frequency * local_t) * np.exp(-local_t * 32)
        end = min(total, start + length)
        audio[start:end] += 0.12 * click[: end - start]

    sparkle_times = np.arange(0.25, DURATION, 1.0)
    for sparkle in sparkle_times:
        start = int(sparkle * SAMPLE_RATE)
        length = int(0.2 * SAMPLE_RATE)
        local_t = np.arange(length) / SAMPLE_RATE
        tone = np.sin(2 * np.pi * root_note * 4 * local_t) * np.exp(-local_t * 24)
        end = min(total, start + length)
        audio[start:end] += 0.035 * tone[: end - start]

    fade = int(0.8 * SAMPLE_RATE)
    audio[:fade] *= np.linspace(0, 1, fade)
    audio[-fade:] *= np.linspace(1, 0, fade)
    audio = np.tanh(audio * 1.8)
    stereo = np.column_stack((audio, audio))
    pcm = np.int16(np.clip(stereo, -1, 1) * 32767)
    output = AUDIO / f"product-{code}-bed.wav"
    with wave.open(str(output), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(pcm.tobytes())
    return output


def build(code, note):
    bed = synth_bed(code, note)
    visual = VISUALS / f"product-{code}-15s-visual.mp4"
    output = FINAL / f"product-{code}-15s.mp4"
    subprocess.run([
        "ffmpeg", "-loglevel", "error", "-y", "-i", str(visual), "-i", str(bed),
        "-map", "0:v:0", "-map", "1:a:0", "-t", "15",
        "-c:v", "copy", "-c:a", "aac", "-ar", "48000", "-ac", "2", "-b:a", "192k",
        "-movflags", "+faststart", str(output),
    ], check=True)
    return output


def main():
    notes = {"A": 220.0, "B": 196.0, "C": 246.94, "D": 174.61}
    for code, note in notes.items():
        print(build(code, note))


if __name__ == "__main__":
    main()
