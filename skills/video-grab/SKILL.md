---
name: video-grab
description: Pull timed screens, the transcript and the video file from YouTube videos into a folder an agent can read. Use when the user wants screens, screenshots, frames or a transcript from a YouTube video, wants to study an app or product from its demo, onboarding or review videos (a UX analysis, a competitor teardown), or says "video-grab".
---

# Video Grab

Turns a YouTube video into evidence an agent can cite: every claim points at a video and a time.

`G=~/.claude/skills/video-grab/scripts/grab.py`. Needs `yt-dlp`, `ffmpeg` and `uv`.

## Steps

1. **Search, and read the dates.** `uv run $G search "<product or topic>" --n 15` lists videos newest first with upload date, length, views and channel. Add `--after YYYY-MM-DD` to drop old ones. Run two or three wordings. An old video shows an old version of the product: pick recent ones first, and keep an old one only when nothing newer covers that part.
2. **Fetch each pick.** `uv run $G fetch <id-or-url> --out <folder>`. For a video over 30 minutes add `--max-frames 120`. Run fetches one after another; the tool itself holds YouTube to two calls at once across every agent on the machine.
3. **Skim the sheets, then open frames.** Read `sheets/sheet-NN.jpg` first: twelve small frames each, with the time printed under each. Open a full frame from `frames/` only where the sheet shows something worth reading. Read `transcript.txt` beside them: its `[m:ss]` marks match the frame times.
4. **Cut the exact moment.** When the transcript names a moment the frames missed ("now tap settings"), `uv run $G at <video-folder> 1:23 4:05` writes full-size frames at those times.
5. **Cite video and time.** Every finding carries the video's URL and the time, and says which it rests on: seen on screen, said by the presenter, or your reading. Quote `age` from `meta.json` for any video it flags OLD.

## Reference

What `fetch` writes to `<folder>/<video-id>/`:

| File | What it holds |
|---|---|
| `meta.json` | Title, channel, URL, upload date, `age` (flags OLD at three years), length, counts |
| `transcript.txt` | The captions as `[m:ss] text`, one line per 15 seconds. Automatic captions mishear names. When YouTube refuses the captions the file says so: fetch again later, and read the screens meanwhile |
| `frames/01m23s.jpg` | A frame at each change of scene and at least one every 20 seconds (`--every`), named by its time |
| `frames.tsv` | Each frame's file and time |
| `sheets/sheet-NN.jpg` | Contact sheets of the frames |
| `source.mp4` | The video, kept so `at` can cut more frames. `--drop-video` deletes it |

`fetch` puts a `.gitignore` holding `*` in `<folder>`: the videos and screens are other people's work, kept on this machine for study and never committed or republished. Write-ups cite the URL and time, and describe a screen in words.
