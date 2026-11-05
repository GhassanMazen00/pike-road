"""Download the licensed (Sonniss GDC bundle) sound files the game uses.

These sounds are royalty-free for use in the game but may not be redistributed as raw
files, so they are NOT committed to git. Run this once on a new machine:

    python -I tools/fetch_licensed_audio.py

It reads tools/licensed_audio_manifest.json and pulls each file straight out of the
bundle zips on the mirror using HTTP range requests (no multi-GB downloads), saving
the raw recordings to _downloads/sonniss/. Then run tools/process_audio.py to cut and
convert them into assets/audio/licensed/.
"""
import io
import json
import os
import sys
import time
import urllib.request
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "licensed_audio_manifest.json")
OUT_DIR = os.path.join(ROOT, "_downloads", "sonniss")
UA = {"User-Agent": "pike-road-dev"}


class HttpFile(io.RawIOBase):
    """Read-only, seekable view of a remote file using HTTP range requests."""

    def __init__(self, url):
        self.url = url
        self.pos = 0
        req = urllib.request.Request(url, method="HEAD", headers=UA)
        with urllib.request.urlopen(req, timeout=60) as r:
            self.size = int(r.headers["Content-Length"])

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.pos

    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else self.pos + offset if whence == 1 else self.size + offset
        return self.pos

    def read(self, n=-1):
        if n is None or n < 0:
            n = self.size - self.pos
        if n <= 0 or self.pos >= self.size:
            return b""
        end = min(self.pos + n, self.size) - 1
        headers = dict(UA, Range="bytes=%d-%d" % (self.pos, end))
        for attempt in range(4):
            try:
                with urllib.request.urlopen(urllib.request.Request(self.url, headers=headers), timeout=120) as r:
                    if r.status != 206:
                        raise IOError("server ignored the range request (status %d)" % r.status)
                    data = r.read()
                break
            except (OSError, IOError):
                if attempt == 3:
                    raise
                time.sleep(2 + attempt * 3)
        self.pos += len(data)
        return data

    def readinto(self, b):
        data = self.read(len(b))
        b[: len(data)] = data
        return len(data)


def _key(name):
    """Compare names on letters and digits only (folder names contain dashes that
    different tools encode differently)."""
    return "".join(ch for ch in name.lower() if ch.isascii() and ch.isalnum())


def _find_member(z, wanted):
    names = z.namelist()
    if wanted in names:
        return wanted
    target = _key(wanted)
    for n in names:
        if _key(n) == target:
            return n
    base = _key(wanted.rsplit("/", 1)[-1])
    for n in names:
        if _key(n.rsplit("/", 1)[-1]) == base:
            return n
    raise KeyError("not found in archive: " + wanted)


def main():
    with open(MANIFEST, encoding="utf-8-sig") as f:
        entries = json.load(f)
    os.makedirs(OUT_DIR, exist_ok=True)
    zips = {}
    for e in entries:
        ext = os.path.splitext(e["member"])[1].lower()
        dest = os.path.join(OUT_DIR, e["name"] + ext)
        if os.path.exists(dest):
            print("have   ", e["name"])
            continue
        if e["url"] not in zips:
            zips[e["url"]] = zipfile.ZipFile(io.BufferedReader(HttpFile(e["url"]), buffer_size=4 << 20))
        z = zips[e["url"]]
        member = _find_member(z, e["member"])
        tmp = dest + ".part"
        with z.open(member) as src, open(tmp, "wb") as dst:
            while True:
                chunk = src.read(4 << 20)
                if not chunk:
                    break
                dst.write(chunk)
        os.replace(tmp, dest)
        print("fetched", e["name"], "(%.1f MB)" % (os.path.getsize(dest) / 1048576))
    print("done")


if __name__ == "__main__":
    sys.exit(main())
