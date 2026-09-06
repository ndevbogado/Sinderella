#!/usr/bin/env python3
"""Genera audio original y liviano para la demo, sin dependencias externas salvo NumPy.

Los WAV quedan sin compresión para que Godot pueda reimportarlos y reemplazarlos
fácilmente. Ejecutá este archivo otra vez si querés regenerar todos los sonidos.
"""

from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
MUSIC_DIR = ROOT / "assets" / "audio" / "music"
SFX_DIR = ROOT / "assets" / "audio" / "sfx"
SR = 32_000
RNG = np.random.default_rng(1847)


def time_axis(duration: float) -> np.ndarray:
    return np.arange(int(duration * SR), dtype=np.float64) / SR


def periodic_sine(target_hz: float, duration: float, phase: float = 0.0) -> np.ndarray:
    t = time_axis(duration)
    cycles = max(1, round(target_hz * duration))
    return np.sin(2.0 * np.pi * cycles * t / duration + phase)


def soft_noise(duration: float, width: int = 25) -> np.ndarray:
    n = int(duration * SR)
    source = RNG.normal(0.0, 1.0, n)
    width = max(1, width)
    # Moving average with wrapped edges: inexpensive and naturally loopable.
    output = np.zeros(n, dtype=np.float64)
    half = width // 2
    for offset in range(-half, half + 1):
        output += np.roll(source, offset)
    return output / math.sqrt(width)


def pluck(track: np.ndarray, start: float, frequency: float, duration: float, amplitude: float) -> None:
    begin = int(start * SR)
    count = min(int(duration * SR), len(track) - begin)
    if count <= 0:
        return
    local_t = np.arange(count, dtype=np.float64) / SR
    attack = np.minimum(local_t / 0.018, 1.0)
    envelope = attack * np.exp(-4.2 * local_t / duration)
    tone = (
        np.sin(2 * np.pi * frequency * local_t)
        + 0.34 * np.sin(2 * np.pi * frequency * 2.01 * local_t + 0.3)
        + 0.12 * np.sin(2 * np.pi * frequency * 3.98 * local_t)
    )
    track[begin : begin + count] += tone * envelope * amplitude


def wrapped_echo(track: np.ndarray, delays: list[tuple[float, float]]) -> np.ndarray:
    result = track.copy()
    for delay, gain in delays:
        result += np.roll(track, int(delay * SR)) * gain
    return result


def fade_edges(track: np.ndarray, duration: float = 0.025) -> np.ndarray:
    count = min(int(duration * SR), len(track) // 2)
    if count <= 0:
        return track
    curve = np.sin(np.linspace(0.0, np.pi / 2.0, count)) ** 2
    track[:count] *= curve
    track[-count:] *= curve[::-1]
    return track


def write_wav(path: Path, samples: np.ndarray, peak: float = 0.90) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    samples = np.nan_to_num(samples)
    maximum = float(np.max(np.abs(samples)))
    if maximum > 0:
        samples = samples / maximum * peak
    pcm = np.asarray(np.clip(samples, -1.0, 1.0) * 32767.0, dtype="<i2")
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SR)
        output.writeframes(pcm.tobytes())


def menu_theme() -> np.ndarray:
    duration = 32.0
    t = time_axis(duration)
    drone = 0.18 * periodic_sine(73.42, duration)
    drone += 0.09 * periodic_sine(110.0, duration, 0.7)
    drone += 0.045 * periodic_sine(146.83, duration, 1.4)
    breath = 0.62 + 0.38 * np.sin(2 * np.pi * t / 8.0 - np.pi / 2.0) ** 2
    track = drone * breath
    notes = [146.83, 174.61, 220.0, 196.0, 146.83, 130.81, 110.0, 130.81]
    for index, note in enumerate(notes):
        pluck(track, index * 4.0 + 0.55, note, 2.2, 0.16)
        if index % 2 == 1:
            pluck(track, index * 4.0 + 2.35, note * 1.5, 1.1, 0.075)
    wind = soft_noise(duration, 51) * (0.012 + 0.006 * np.sin(2 * np.pi * t / 8.0))
    return wrapped_echo(track + wind, [(0.21, 0.16), (0.43, 0.09), (0.83, 0.045)])


def cinematic_theme() -> np.ndarray:
    duration = 32.0
    t = time_axis(duration)
    track = 0.17 * periodic_sine(55.0, duration)
    track += 0.085 * periodic_sine(82.41, duration, 0.8)
    track *= 0.74 + 0.26 * np.sin(2 * np.pi * t / 6.4) ** 2
    motif = [110.0, 130.81, 146.83, 130.81, 98.0, 110.0, 82.41, 98.0]
    for index, note in enumerate(motif):
        start = index * 4.0 + 0.35
        pluck(track, start, note, 2.4, 0.12)
        pluck(track, start + 1.6, note * 2.0, 1.0, 0.055)
        # Low, restrained impact marking each visual phrase.
        begin = int((index * 4.0) * SR)
        count = min(int(0.8 * SR), len(track) - begin)
        local_t = np.arange(count) / SR
        impact = np.sin(2 * np.pi * (48.0 - 22.0 * local_t) * local_t) * np.exp(-7.0 * local_t)
        track[begin : begin + count] += impact * 0.11
    track += soft_noise(duration, 65) * 0.012
    return wrapped_echo(track, [(0.17, 0.12), (0.36, 0.075), (0.72, 0.035)])


def room_theme() -> np.ndarray:
    duration = 24.0
    t = time_axis(duration)
    track = 0.07 * periodic_sine(73.42, duration)
    track += 0.035 * periodic_sine(110.0, duration, 1.2)
    track *= 0.55 + 0.45 * np.sin(2 * np.pi * t / 12.0) ** 2
    notes = [146.83, 174.61, 196.0, 174.61, 130.81, 146.83]
    for index, note in enumerate(notes):
        pluck(track, index * 4.0 + 0.8, note, 2.0, 0.115)
        pluck(track, index * 4.0 + 2.55, note * 1.5, 1.0, 0.048)
    return wrapped_echo(track, [(0.23, 0.13), (0.51, 0.07)])


def city_ambience() -> np.ndarray:
    duration = 18.0
    t = time_axis(duration)
    wind = soft_noise(duration, 81) * (0.045 + 0.018 * np.sin(2 * np.pi * t / 9.0))
    rumble = periodic_sine(36.0, duration) * 0.018
    ambience = wind + rumble
    for start in (3.2, 12.1):
        pluck(ambience, start, 196.0, 3.2, 0.045)
        pluck(ambience, start + 0.08, 98.0, 3.2, 0.035)
    return wrapped_echo(ambience, [(0.63, 0.11), (1.19, 0.06)])


def room_ambience() -> np.ndarray:
    duration = 18.0
    t = time_axis(duration)
    wind = soft_noise(duration, 97) * (0.022 + 0.01 * np.sin(2 * np.pi * t / 6.0))
    fire = soft_noise(duration, 9) * (0.008 + 0.005 * np.sin(2 * np.pi * t * 0.8) ** 2)
    ambience = wind + fire
    # Two subtle wooden creaks.
    for start in (5.4, 14.0):
        begin = int(start * SR)
        count = min(int(1.4 * SR), len(ambience) - begin)
        local_t = np.arange(count) / SR
        chirp = np.sin(2 * np.pi * (92.0 - 38.0 * local_t) * local_t) * np.sin(np.pi * local_t / 1.4) ** 2
        ambience[begin : begin + count] += chirp * 0.025
    return ambience


def simple_tone(duration: float, frequencies: tuple[float, ...], decay: float = 6.0) -> np.ndarray:
    t = time_axis(duration)
    envelope = np.minimum(t / 0.008, 1.0) * np.exp(-decay * t / duration)
    tone = sum(np.sin(2 * np.pi * frequency * t) / (index + 1) for index, frequency in enumerate(frequencies))
    return fade_edges(tone * envelope)


def panel_in() -> np.ndarray:
    duration = 0.38
    t = time_axis(duration)
    noise = soft_noise(duration, 5)
    envelope = np.sin(np.pi * np.clip(t / duration, 0.0, 1.0)) ** 2
    sweep_phase = 2 * np.pi * (190.0 * t + 480.0 * t * t)
    return fade_edges((0.32 * noise + 0.22 * np.sin(sweep_phase)) * envelope)


def page_step() -> np.ndarray:
    duration = 0.18
    t = time_axis(duration)
    envelope = np.sin(np.pi * t / duration) ** 2
    return fade_edges((soft_noise(duration, 3) * 0.30 + np.sin(2 * np.pi * 520 * t) * 0.05) * envelope)


def prison_gate() -> np.ndarray:
    duration = 2.1
    t = time_axis(duration)
    scrape = soft_noise(duration, 7) * np.exp(-0.65 * t)
    groan = np.sin(2 * np.pi * (58.0 - 12.0 * t) * t) * np.sin(np.pi * np.clip(t / duration, 0, 1))
    clank = np.zeros_like(t)
    for start in (0.08, 1.72):
        begin = int(start * SR)
        count = min(int(0.32 * SR), len(clank) - begin)
        local_t = np.arange(count) / SR
        clank[begin : begin + count] += np.sin(2 * np.pi * 218 * local_t) * np.exp(-17 * local_t)
    return fade_edges(scrape * 0.22 + groan * 0.34 + clank * 0.42)


def footstep() -> np.ndarray:
    duration = 0.22
    t = time_axis(duration)
    thump = np.sin(2 * np.pi * 78 * t) * np.exp(-28 * t)
    knock = soft_noise(duration, 3) * np.exp(-34 * t)
    return fade_edges(thump * 0.55 + knock * 0.20)


def main() -> None:
    music = {
        "menu_theme.wav": menu_theme(),
        "cinematic_theme.wav": cinematic_theme(),
        "room_theme.wav": room_theme(),
        "city_ambience.wav": city_ambience(),
        "room_ambience.wav": room_ambience(),
    }
    sfx = {
        "ui_confirm.wav": simple_tone(0.24, (440.0, 660.0, 880.0), 7.5),
        "ui_open.wav": simple_tone(0.20, (330.0, 495.0), 8.5),
        "ui_back.wav": simple_tone(0.18, (360.0, 240.0), 9.0),
        "panel_in.wav": panel_in(),
        "page_step.wav": page_step(),
        "prison_gate.wav": prison_gate(),
        "footstep_wood.wav": footstep(),
    }
    for filename, samples in music.items():
        write_wav(MUSIC_DIR / filename, samples, 0.72)
    for filename, samples in sfx.items():
        write_wav(SFX_DIR / filename, samples, 0.84)
    print(f"Generated {len(music)} music/ambience files and {len(sfx)} SFX files.")


if __name__ == "__main__":
    main()

