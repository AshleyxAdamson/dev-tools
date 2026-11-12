# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow"]
# ///
"""Screens, transcript and the video file from a YouTube video, in a folder an agent can read.

    uv run grab.py search "<query>" [--n 12] [--after YYYY-MM-DD]
    uv run grab.py fetch <url-or-id> --out <folder> [--max-frames 60] [--every 20] [--drop-video]
    uv run grab.py at <video-folder> 1:23 4:05

Needs yt-dlp and ffmpeg on the PATH. Grown from tools/grab_episodes.py in the Rick and Morty card project.
"""
from __future__ import annotations

import argparse
import contextlib
import fcntl
import html
import json
import os
import re
import subprocess
import sys
import time
from datetime import date, datetime
from pathlib import Path

YT_SLOTS = 2  # yt-dlp calls at once on this machine, however many agents run it
LOCKS = Path.home() / ".cache" / "video-grab"
OLD_AFTER_YEARS = 3
SHEET_COLS, SHEET_ROWS, THUMB_W, LABEL_H = 4, 3, 480, 26


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


@contextlib.contextmanager
def youtube_slot():
    """Hold one of YT_SLOTS locks for a yt-dlp call, so a fan-out of agents never sends YouTube a burst."""
    LOCKS.mkdir(parents=True, exist_ok=True)
    fds = [os.open(str(LOCKS / f"yt-slot-{i}.lock"), os.O_CREAT | os.O_RDWR) for i in range(YT_SLOTS)]
    try:
        held = False
        while not held:
            for fd in fds:
                try:
                    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    held = True
                    break
                except OSError:
                    continue
            if not held:
                time.sleep(1)
        yield
    finally:
        for fd in fds:
            os.close(fd)


# ---------- small pure helpers ----------
def video_url(url_or_id: str) -> str:
    s = url_or_id.strip()
    return "https://www.youtube.com/watch?v=" + s if re.fullmatch(r"[\w-]{11}", s) else s


def label(seconds: float) -> str:
    """83.4 -> '01m23s'; an hour or more -> '1h02m03s'."""
    s = int(seconds)
    h, m, sec = s // 3600, (s % 3600) // 60, s % 60
    return f"{h}h{m:02d}m{sec:02d}s" if h else f"{m:02d}m{sec:02d}s"


def clock(seconds: float) -> str:
    """83.4 -> '1:23'; an hour or more -> '1:02:03'."""
    s = int(seconds)
    h, m, sec = s // 3600, (s % 3600) // 60, s % 60
    return f"{h}:{m:02d}:{sec:02d}" if h else f"{m}:{sec:02d}"


def parse_time(text: str) -> float:
    """'83', '1:23' or '1:02:03' -> seconds."""
    parts = [float(p) for p in text.strip().split(":")]
    if not 1 <= len(parts) <= 3:
        raise ValueError(f"not a time: {text}")
    seconds = 0.0
    for p in parts:
        seconds = seconds * 60 + p
    return seconds


def upload_day(yyyymmdd: str | None) -> date | None:
    try:
        return datetime.strptime(yyyymmdd or "", "%Y%m%d").date()
    except ValueError:
        return None


def age_note(day: date | None, today: date | None = None) -> str:
    if day is None:
        return "upload date unknown"
    years = ((today or date.today()) - day).days / 365.25
    note = f"uploaded {day.isoformat()}, {years:.1f} years ago"
    return note + " (OLD: the app may have changed since)" if years >= OLD_AFTER_YEARS else note


_CUE = re.compile(r"(\d+):(\d\d):(\d\d)[.,](\d{3})\s+-->")
_TAG = re.compile(r"<[^>]+>")


def vtt_lines(vtt: str, bucket: int = 15) -> list[tuple[float, str]]:
    """A VTT file as (start seconds, text) lines, one per `bucket` seconds of speech.

    YouTube's automatic captions repeat each line as it scrolls; a line equal to the one before it is dropped.
    """
    spoken: list[tuple[float, str]] = []
    start, last = None, None
    for raw in vtt.splitlines():
        m = _CUE.match(raw.strip())
        if m:
            h, mi, s, ms = (int(x) for x in m.groups())
            start = h * 3600 + mi * 60 + s + ms / 1000
            continue
        text = html.unescape(_TAG.sub("", raw)).replace("\xa0", " ").strip()
        if start is None or not text or text == last:
            continue
        spoken.append((start, text))
        last = text
    out: list[tuple[float, str]] = []
    for at, text in spoken:
        if out and at - out[-1][0] < bucket:
            out[-1] = (out[-1][0], out[-1][1] + " " + text)
        else:
            out.append((at, text))
    return out


def frame_names(times: list[float]) -> list[str]:
    """One file name per frame time; two frames in the same second get -b, -c."""
    seen: dict[str, int] = {}
    names = []
    for t in times:
        base = label(t)
        n = seen.get(base, 0)
        seen[base] = n + 1
        names.append(base + (f"-{chr(ord('a') + n)}" if n else "") + ".jpg")
    return names


# ---------- search ----------
def search(query: str, n: int, after: str | None) -> int:
    fields = "%(id)s\t%(upload_date)s\t%(duration)s\t%(view_count)s\t%(channel)s\t%(title)s"
    with youtube_slot():
        r = run(["yt-dlp", f"ytsearch{n}:{query}", "--print", fields, "--no-warnings", "--ignore-errors"])
    rows = []
    for line in r.stdout.splitlines():
        parts = line.split("\t", 5)
        if len(parts) == 6:
            rows.append(parts)
    if not rows:
        print("no results" + (": " + r.stderr.strip()[-300:] if r.stderr.strip() else ""), file=sys.stderr)
        return 1
    cut = datetime.strptime(after, "%Y-%m-%d").date() if after else None
    rows.sort(key=lambda p: p[1], reverse=True)  # newest first
    print("id\tuploaded\tlength\tviews\tchannel\ttitle")
    for vid, up, dur, views, channel, title in rows:
        day = upload_day(up)
        if cut and (day is None or day < cut):
            continue
        length = clock(float(dur)) if dur.replace(".", "", 1).isdigit() else "?"
        print("\t".join([vid, day.isoformat() if day else "?", length, views, channel, title]))
    return 0


# ---------- fetch ----------
def cut_frames(video: Path, frames: Path, duration: float, max_frames: int, every: float) -> list[tuple[str, float]]:
    """A frame at each change of scene, and at least one every `every` seconds. Returns (file name, seconds)."""
    every = max(every, duration / max_frames) if duration else every
    threshold = 0.1
    while True:
        for old in frames.glob("*.jpg"):
            old.unlink()
        pick = f"gt(scene,{threshold})+isnan(prev_selected_t)+gte(t-prev_selected_t,{every:.1f})"
        r = run(["ffmpeg", "-y", "-hide_banner", "-i", str(video), "-vf",
                 f"select='{pick}',showinfo,scale='min(1600,iw)':-2", "-fps_mode", "vfr", "-q:v", "3",
                 str(frames / "raw-%05d.jpg")])
        if r.returncode != 0:
            raise RuntimeError(r.stderr[-400:])
        times = [float(t) for t in re.findall(r"Parsed_showinfo.*?pts_time:\s*([\d.]+)", r.stderr)]
        raw = sorted(frames.glob("raw-*.jpg"))
        if len(raw) <= max_frames * 1.2 or threshold >= 0.9:
            break
        threshold = round(threshold + 0.1, 2)
    if len(times) != len(raw):  # showinfo and the files disagree: fall back to even spacing so names still sort
        times = [i * duration / max(len(raw), 1) for i in range(len(raw))]
    out = []
    for path, name, t in zip(raw, frame_names(times), times):
        path.rename(frames / name)
        out.append((name, t))
    return out


def make_sheets(frames: Path, sheets: Path, listed: list[tuple[str, float]]) -> int:
    """Contact sheets: every frame small, its time printed under it, so an agent can skim a video in a few images."""
    from PIL import Image, ImageDraw

    per = SHEET_COLS * SHEET_ROWS
    for old in sheets.glob("*.jpg"):
        old.unlink()
    count = 0
    for i in range(0, len(listed), per):
        chunk = listed[i:i + per]
        thumbs = []
        for name, t in chunk:
            im = Image.open(frames / name).convert("RGB")
            im.thumbnail((THUMB_W, THUMB_W))
            thumbs.append((im, clock(t)))
        cell_h = max(im.height for im, _ in thumbs) + LABEL_H
        rows = -(-len(thumbs) // SHEET_COLS)
        sheet = Image.new("RGB", (SHEET_COLS * THUMB_W, rows * cell_h), "white")
        draw = ImageDraw.Draw(sheet)
        for n, (im, text) in enumerate(thumbs):
            x, y = (n % SHEET_COLS) * THUMB_W, (n // SHEET_COLS) * cell_h
            sheet.paste(im, (x, y))
            draw.text((x + 6, y + cell_h - LABEL_H + 4), text, fill="black", font_size=18)
        count += 1
        sheet.save(sheets / f"sheet-{count:02d}.jpg", quality=85)
    return count


CAPTION_NOTES = {
    "none": "(no captions on this video)",
    "blocked": "(YouTube refused the captions: too many requests. Run fetch again in a few minutes.)",
}


def fetch_captions(url: str, folder: Path, tries: int = 3, wait: float = 30) -> tuple[list[tuple[float, str]], str]:
    """The English captions as lines, and 'ok', 'none' or 'blocked'. Kept apart from the video download:
    YouTube refuses captions (HTTP 429) far sooner than video, and a refusal must not lose the video."""
    stderr = ""
    for attempt in range(tries):
        with youtube_slot():
            r = run(["yt-dlp", "--skip-download", "--write-subs", "--write-auto-subs", "--sub-langs", "en,en-orig",
                     "--sub-format", "vtt", "--sleep-subtitles", "2", "--no-warnings",
                     "-o", str(folder / "source.%(ext)s"), url])
        stderr = r.stderr
        subs = sorted(folder.glob("source.*.vtt"), key=lambda p: ("orig" in p.name, len(p.name)))
        if subs:
            lines = vtt_lines(subs[0].read_text(encoding="utf-8", errors="replace"))
            for p in subs:
                p.unlink()
            return lines, "ok" if lines else "none"
        if "429" not in stderr:
            return [], "none"
        if attempt < tries - 1:
            time.sleep(wait)
    return [], "blocked"


def fetch(url_or_id: str, out: Path, max_frames: int, every: float, drop_video: bool, height: int) -> int:
    url = video_url(url_or_id)
    out.mkdir(parents=True, exist_ok=True)
    ignore = out / ".gitignore"
    if not ignore.exists():  # other people's videos and screens never go into a repo by accident
        ignore.write_text("*\n", encoding="utf-8")
    with youtube_slot():
        r = run(["yt-dlp", "--dump-json", "--no-download", "--no-warnings", url])
    if r.returncode != 0:
        print("can't read the video: " + r.stderr.strip()[-300:], file=sys.stderr)
        return 1
    info = json.loads(r.stdout.splitlines()[0])
    folder = out / info["id"]
    frames, sheets = folder / "frames", folder / "sheets"
    for d in (frames, sheets):
        d.mkdir(parents=True, exist_ok=True)
    with youtube_slot():
        r = run(["yt-dlp", "-f", f"bv*[height<={height}]+ba/b[height<={height}]", "--merge-output-format", "mp4",
                 "--no-warnings", "-o", str(folder / "source.%(ext)s"), url])
    video = folder / "source.mp4"
    if not video.exists():
        print("download failed: " + r.stderr.strip()[-300:], file=sys.stderr)
        return 1

    lines, captions = fetch_captions(url, folder)
    (folder / "transcript.txt").write_text(
        "".join(f"[{clock(t)}] {text}\n" for t, text in lines) or CAPTION_NOTES[captions] + "\n", encoding="utf-8")

    duration = float(info.get("duration") or 0)
    listed = cut_frames(video, frames, duration, max_frames, every)
    (folder / "frames.tsv").write_text(
        "file\tseconds\ttime\n" + "".join(f"frames/{n}\t{t:.1f}\t{clock(t)}\n" for n, t in listed), encoding="utf-8")
    n_sheets = make_sheets(frames, sheets, listed)

    day = upload_day(info.get("upload_date"))
    meta = {"id": info["id"], "url": info.get("webpage_url") or url, "title": info.get("title"),
            "channel": info.get("channel"), "uploaded": day.isoformat() if day else None, "age": age_note(day),
            "duration_seconds": duration, "views": info.get("view_count"), "frames": len(listed),
            "sheets": n_sheets, "transcript_lines": len(lines), "captions": captions,
            "video_kept": not drop_video}
    (folder / "meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8")
    if drop_video:
        video.unlink()
    print(f"{folder}\n  {meta['title']} ({meta['channel']})\n  {meta['age']}, {clock(duration)} long\n"
          f"  {len(listed)} frames on {n_sheets} sheets, {len(lines)} transcript lines"
          + ("" if lines else " " + CAPTION_NOTES[captions]))
    return 0


# ---------- at ----------
def at(folder: Path, times: list[str]) -> int:
    video = folder / "source.mp4"
    if not video.exists():
        print(f"no source.mp4 in {folder}: fetch it again without --drop-video", file=sys.stderr)
        return 1
    for text in times:
        t = parse_time(text)
        target = folder / "frames" / f"at-{label(t)}.jpg"
        r = run(["ffmpeg", "-y", "-loglevel", "error", "-ss", f"{t:.2f}", "-i", str(video), "-frames:v", "1",
                 "-q:v", "2", str(target)])
        print(target if r.returncode == 0 and target.exists() else f"failed at {text}: {r.stderr.strip()[-200:]}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="grab.py", description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("search", help="list videos for a query, newest first, with upload dates")
    s.add_argument("query")
    s.add_argument("--n", type=int, default=12)
    s.add_argument("--after", help="only videos uploaded on or after YYYY-MM-DD")
    f = sub.add_parser("fetch", help="download one video; write frames, contact sheets and the transcript")
    f.add_argument("url")
    f.add_argument("--out", required=True, type=Path)
    f.add_argument("--max-frames", type=int, default=60)
    f.add_argument("--every", type=float, default=20, help="at least one frame every this many seconds")
    f.add_argument("--height", type=int, default=1080)
    f.add_argument("--drop-video", action="store_true", help="delete the video file once the frames are cut")
    a = sub.add_parser("at", help="cut a full-size frame at exact times from a fetched video")
    a.add_argument("folder", type=Path)
    a.add_argument("times", nargs="+")
    args = p.parse_args()
    if args.cmd == "search":
        return search(args.query, args.n, args.after)
    if args.cmd == "fetch":
        return fetch(args.url, args.out, args.max_frames, args.every, args.drop_video, args.height)
    return at(args.folder, args.times)


if __name__ == "__main__":
    sys.exit(main())
