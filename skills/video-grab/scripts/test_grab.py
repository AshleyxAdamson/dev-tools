"""Run:  uv run --with pytest --with pillow pytest scripts/test_grab.py -q   (from the skill folder)"""
from datetime import date

import grab

AUTO_VTT = """WEBVTT
Kind: captions
Language: en

00:00:00.160 --> 00:00:02.230 align:start position:0%

hello<00:00:00.480><c> and</c><00:00:00.640><c> welcome</c>

00:00:02.230 --> 00:00:02.240 align:start position:0%
hello and welcome


00:00:02.240 --> 00:00:04.000 align:start position:0%
hello and welcome
to<00:00:02.400><c> the</c><00:00:02.560><c> app</c>

00:00:31.000 --> 00:00:33.000
&gt;&gt; tap the &amp; key
"""


def test_vtt_drops_the_scrolling_repeats_and_groups_by_time():
    assert grab.vtt_lines(AUTO_VTT) == [(0.16, "hello and welcome to the app"), (31.0, ">> tap the & key")]


def test_vtt_with_no_cues_is_empty():
    assert grab.vtt_lines("WEBVTT\n\n") == []


def test_labels_and_clock():
    assert grab.label(83.4) == "01m23s"
    assert grab.label(3723) == "1h02m03s"
    assert grab.clock(83.4) == "1:23"
    assert grab.clock(3723) == "1:02:03"


def test_parse_time():
    assert grab.parse_time("83") == 83
    assert grab.parse_time("1:23") == 83
    assert grab.parse_time("1:02:03") == 3723


def test_two_frames_in_one_second_get_their_own_names():
    assert grab.frame_names([5.1, 5.6, 5.9, 70]) == ["00m05s.jpg", "00m05s-b.jpg", "00m05s-c.jpg", "01m10s.jpg"]


def test_video_url_takes_an_id_or_a_url():
    assert grab.video_url("dQw4w9WgXcQ") == "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    assert grab.video_url("https://youtu.be/dQw4w9WgXcQ") == "https://youtu.be/dQw4w9WgXcQ"


def test_old_videos_are_flagged():
    today = date(2026, 11, 11)
    assert "OLD" in grab.age_note(date(2019, 5, 1), today)
    assert "OLD" not in grab.age_note(date(2025, 5, 1), today)
    assert grab.age_note(None, today) == "upload date unknown"
    assert grab.upload_day("20240229") == date(2024, 2, 29)
    assert grab.upload_day("NA") is None
