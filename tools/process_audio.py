"""Turn the raw licensed recordings in _downloads/sonniss/ into game-ready files
in assets/audio/licensed/ (git-ignored, see .gitignore).

    python -I tools/process_audio.py

- Footstep loops are cut into single steps (onset detection), normalised, faded.
- Multi-take files are split into separate takes.
- Ambiences are trimmed and crossfaded so they loop without a click.
- Everything is written as 16-bit PCM WAV at <= 48 kHz.
Pure standard library (no numpy), so it is not fast, but it only runs once.
"""
import array
import math
import os
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "_downloads", "sonniss")
DST = os.path.join(ROOT, "assets", "audio", "licensed")


# ---------------------------------------------------------------- reading

def read_wav(path, max_seconds=None):
    """Returns (rate, [channel arrays of floats in -1..1])."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise ValueError("not a RIFF/WAVE file: " + path)
    pos = 12
    fmt = None
    pcm = None
    while pos + 8 <= len(data):
        cid = data[pos:pos + 4]
        size = struct.unpack_from("<I", data, pos + 4)[0]
        body_start = pos + 8
        if cid == b"fmt ":
            tag, ch, rate, _, _, bits = struct.unpack_from("<HHIIHH", data, body_start)
            if tag == 0xFFFE:  # WAVE_FORMAT_EXTENSIBLE: real format in the sub-format GUID
                tag = struct.unpack_from("<H", data, body_start + 24)[0]
            fmt = (tag, ch, rate, bits)
        elif cid == b"data":
            pcm = memoryview(data)[body_start:body_start + size]
        pos = body_start + size + (size & 1)
    if fmt is None or pcm is None:
        raise ValueError("missing fmt/data chunk: " + path)
    tag, ch, rate, bits = fmt
    frame_bytes = ch * bits // 8
    if max_seconds:
        pcm = pcm[: min(len(pcm), int(max_seconds * rate) * frame_bytes)]
    n = len(pcm) // (bits // 8)
    pcm = pcm[: n * (bits // 8)]
    if tag == 3 and bits == 32:
        samples = array.array("f", bytes(pcm))
        scale = 1.0
    elif tag == 1 and bits == 16:
        samples = array.array("h", bytes(pcm))
        scale = 1.0 / 32768.0
    elif tag == 1 and bits == 24:
        b32 = bytearray(n * 4)
        b32[1::4] = pcm[0::3]
        b32[2::4] = pcm[1::3]
        b32[3::4] = pcm[2::3]
        samples = array.array("i", bytes(b32))
        scale = 1.0 / 2147483648.0
    elif tag == 1 and bits == 32:
        samples = array.array("i", bytes(pcm))
        scale = 1.0 / 2147483648.0
    else:
        raise ValueError("unsupported format tag=%d bits=%d in %s" % (tag, bits, path))
    chans = []
    for c in range(min(ch, 2)):  # keep L/R only (5.1 files: front left/right)
        chans.append([s * scale for s in samples[c::ch]])
    # downsample high rates by averaging pairs (cheap low-pass)
    while rate > 48000:
        chans = [[(a + b) * 0.5 for a, b in zip(x[0::2], x[1::2])] for x in chans]
        rate //= 2
    return rate, chans


def to_mono(chans):
    if len(chans) == 1:
        return chans[0]
    return [(a + b) * 0.5 for a, b in zip(chans[0], chans[1])]


# ---------------------------------------------------------------- writing

def write_wav(path, rate, chans):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    n = len(chans[0])
    out = array.array("h", bytes(2 * n * len(chans)))
    for c, x in enumerate(chans):
        out[c::len(chans)] = array.array("h", (max(-32767, min(32767, int(v * 32767))) for v in x))
    with wave.open(path, "wb") as w:
        w.setnchannels(len(chans))
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(out.tobytes())


# ---------------------------------------------------------------- helpers

def peak(x):
    return max(max(x), -min(x)) if x else 0.0


def rms(x):
    return math.sqrt(sum(v * v for v in x) / len(x)) if x else 0.0


def gain(x, g):
    return [v * g for v in x]


def fade(x, rate, fin=0.003, fout=0.04):
    x = list(x)
    a = max(1, int(fin * rate))
    b = max(1, int(fout * rate))
    for i in range(min(a, len(x))):
        x[i] *= i / a
    for i in range(min(b, len(x))):
        x[-1 - i] *= i / b
    return x


def envelope(x, rate, win=0.005):
    w = max(1, int(win * rate))
    return [max(map(abs, x[i:i + w])) for i in range(0, len(x), w)], w


def onsets(x, rate, min_gap, threshold=0.18, rise=2.2):
    """Indices (samples) where loudness jumps: footsteps or takes."""
    env, w = envelope(x, rate)
    top = max(env) or 1.0
    gap = int(min_gap * rate / w)
    found = []
    last = -gap
    for i in range(4, len(env)):
        before = sum(env[i - 4:i]) / 4 + 1e-9
        if env[i] > threshold * top and env[i] > rise * before and i - last >= gap:
            found.append(i * w)
            last = i
    return found


def split(x, rate, min_gap, length, pre=0.012, threshold=0.18, rise=2.2):
    cuts = []
    starts = onsets(x, rate, min_gap, threshold, rise)
    for k, s in enumerate(starts):
        a = max(0, s - int(pre * rate))
        b = min(len(x), a + int(length * rate))
        if k + 1 < len(starts):
            b = min(b, starts[k + 1] - int(pre * rate))
        seg = x[a:b]
        if len(seg) > 0.08 * rate:
            cuts.append(seg)
    return cuts


def normalise_rms(seg, target=0.12, ceiling=0.89):
    r = rms(seg) or 1e-9
    g = target / r
    p = peak(seg) * g
    if p > ceiling:
        g *= ceiling / p
    return gain(seg, g)


def trim_silence(x, rate, floor=0.01, keep=0.02):
    p = peak(x) or 1.0
    idx = [i for i in range(0, len(x), 64) if abs(x[i]) > floor * p]
    if not idx:
        return x
    a = max(0, idx[0] - int(keep * rate))
    b = min(len(x), idx[-1] + int(0.15 * rate))
    return x[a:b]


def loop_crossfade(chans, rate, seconds, xfade=2.0):
    """Cut `seconds` (+ xfade) and blend the tail into the head so the loop is seamless."""
    n = int(seconds * rate)
    f = int(xfade * rate)
    out = []
    for x in chans:
        x = x[: n + f]
        if len(x) < n + f:
            n2 = len(x) - f
        else:
            n2 = n
        body = x[:n2]
        for i in range(f):
            t = i / f
            body[i] = body[i] * t + x[n2 + i] * (1.0 - t)
        out.append(body)
    return out


# ---------------------------------------------------------------- jobs

def src(name):
    for ext in (".wav", ".WAV", ".Wav"):
        p = os.path.join(SRC, name + ext)
        if os.path.exists(p):
            return p
    raise FileNotFoundError(name)


def steps(source, surface, count=12, min_gap=0.3, length=0.42, max_seconds=60, offset=0, threshold=0.18):
    rate, ch = read_wav(src(source), max_seconds)
    x = to_mono(ch)
    segs = split(x, rate, min_gap, length, threshold=threshold)
    segs = segs[offset:offset + count]
    for i, seg in enumerate(segs):
        write_wav(os.path.join(DST, "footsteps", surface, "%s_%02d.wav" % (source, i + 1)), rate,
                  [fade(normalise_rms(seg), rate)])
    print("steps   %-24s -> %-8s %d cuts" % (source, surface, len(segs)))


def takes(source, out_name, min_gap=0.8, length=4.0, count=8, target=0.14, threshold=0.25, max_seconds=120):
    rate, ch = read_wav(src(source), max_seconds)
    x = to_mono(ch)
    segs = split(x, rate, min_gap, length, pre=0.02, threshold=threshold)[:count]
    for i, seg in enumerate(segs):
        seg = trim_silence(seg, rate)
        write_wav(os.path.join(DST, "sfx", "%s_%02d.wav" % (out_name, i + 1)), rate,
                  [fade(normalise_rms(seg, target), rate, 0.002, 0.08)])
    print("takes   %-24s -> %-22s %d" % (source, out_name, len(segs)))


def oneshot(source, out_name, max_len=10.0, target=0.14, stereo=False):
    rate, ch = read_wav(src(source), max_len + 2)
    chans = ch if stereo else [to_mono(ch)]
    trimmed = []
    mono = to_mono(ch)
    p = peak(mono) or 1.0
    idx = [i for i in range(0, len(mono), 64) if abs(mono[i]) > 0.01 * p]
    a = max(0, (idx[0] if idx else 0) - int(0.02 * rate))
    b = min(len(mono), (idx[-1] if idx else len(mono)) + int(0.2 * rate), a + int(max_len * rate))
    g = target / (rms(mono[a:b]) or 1e-9)
    g = min(g, 0.89 / (peak(mono[a:b]) or 1e-9))
    for x in chans:
        trimmed.append(fade(gain(x[a:b], g), rate, 0.002, 0.15))
    write_wav(os.path.join(DST, "sfx", out_name + ".wav"), rate, trimmed)
    print("oneshot %-24s -> %s (%.1fs)" % (source, out_name, (b - a) / rate))


def ambience(source, out_name, seconds=75, target=0.05, skip=5.0):
    rate, ch = read_wav(src(source), seconds + skip + 3)
    s = int(skip * rate)
    ch = [x[s:] for x in ch]
    ch = loop_crossfade(ch, rate, seconds)
    mono = to_mono(ch)
    g = target / (rms(mono) or 1e-9)
    write_wav(os.path.join(DST, "ambience", out_name + ".wav"), rate, [gain(x, g) for x in ch])
    print("ambience %-23s -> %s (%ds)" % (source, out_name, seconds))


JOBS = [
    # footsteps
    lambda: steps("steps_wood_stairs_loop", "wood", count=14, offset=1),
    lambda: steps("steps_wood_stairs_loop", "stairs", count=10, offset=16),
    lambda: steps("steps_carpet_loop", "carpet", count=14, offset=1),
    lambda: steps("steps_gravel_loop", "dirt", count=14, offset=1, min_gap=0.28),
    lambda: steps("steps_leaves", "leaves", count=14, offset=1, min_gap=0.28, length=0.5),
    # doors and house
    lambda: oneshot("door_open_haunted", "door_open_creak", max_len=4.0),
    lambda: oneshot("door_close_haunted", "door_slam_scary", max_len=6.0, stereo=True),
    lambda: oneshot("door_close_long_creak", "door_close_creak", max_len=5.0),
    lambda: oneshot("door_knob_turn", "door_knob", max_len=2.5),
    lambda: oneshot("door_big_close", "door_close", max_len=2.5),
    lambda: oneshot("door_lock", "door_locked_rattle", max_len=2.0),
    lambda: oneshot("deadbolt", "deadbolt", max_len=2.0),
    lambda: oneshot("door_bang", "door_bang", max_len=4.0),
    lambda: oneshot("fridge_open", "fridge_open", max_len=3.0),
    lambda: oneshot("microwave_door", "microwave_door", max_len=2.0),
    lambda: oneshot("breaker_switch", "breaker_switch", max_len=2.0),
    lambda: oneshot("cupboard_open", "cupboard_open", max_len=2.5),
    lambda: takes("drawers_open", "drawer_open", min_gap=0.9, length=2.0, count=8),
    lambda: takes("drawers_close", "drawer_close", min_gap=0.7, length=1.5, count=6),
    lambda: takes("door_hinge_creaky", "hinge_creak", min_gap=1.5, length=4.0, count=3, threshold=0.15),
    lambda: takes("cabinet_glass_close", "cabinet_close", min_gap=0.9, length=1.6, count=5),
    lambda: takes("doorknob_creak", "doorknob_creak", min_gap=1.2, length=3.0, count=5, threshold=0.15),
    lambda: takes("knock_fist", "knock", min_gap=0.25, length=0.6, count=12),
    lambda: takes("pound_impatient", "pound", min_gap=0.12, length=0.5, count=16),
    lambda: oneshot("door_kick_rattle", "door_rattle_violent", max_len=8.0, stereo=True),
    lambda: takes("floorboard_creak", "creak_floor", min_gap=1.0, length=3.0, count=4, threshold=0.12),
    lambda: takes("wood_floor_creak", "creak_wood", min_gap=1.0, length=3.0, count=4, threshold=0.12),
    lambda: takes("microwave_beeps", "microwave_beep", min_gap=0.15, length=0.35, count=6),
    lambda: oneshot("doormat_scrape", "doormat_scrape", max_len=3.0),
    # people and tension
    lambda: oneshot("heartbeat", "heartbeat_panic", max_len=30.0, target=0.2),
    lambda: oneshot("scream_male_covered", "scream_muffled", max_len=4.0, target=0.2),
    lambda: oneshot("radio_static", "tv_static", max_len=20.0, target=0.08, stereo=True),
    lambda: oneshot("clock_023", "clock_tick_a", max_len=12.0, target=0.08),
    lambda: oneshot("clock_070", "clock_tick_b", max_len=12.0, target=0.08),
    # ambience
    lambda: ambience("room_tone_household", "room_tone_house", seconds=75, target=0.035),
    lambda: ambience("room_tone_furnace", "room_tone_basement", seconds=60, target=0.05),
    lambda: ambience("night_crickets_owls", "night_outside", seconds=90, target=0.06),
    lambda: ambience("crickets_quiet", "crickets_quiet", seconds=60, target=0.05),
    lambda: ambience("tree_creaks", "forest_creaks", seconds=75, target=0.05),
]


def main():
    only = sys.argv[1:]
    failures = 0
    for i, job in enumerate(JOBS):
        if only and str(i) not in only:
            continue
        try:
            job()
        except Exception as e:  # keep going; report at the end
            failures += 1
            print("FAILED job %d: %s" % (i, e))
    print("done, %d failed" % failures)


if __name__ == "__main__":
    main()
