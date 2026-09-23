#!/usr/bin/env python3
"""Cut the numbered episodes from a local copy of the 72-minute compilation.

Usage: python3 tools/generate_episodes.py /path/to/lalinea.webm [--only 101]
The source is never copied into the plugin. The boundaries include each
episode's title and ending; each 30-second WebP stays below the QMovie RAM
budget, while the Ogg track plays continuously across its visual chunks.
"""

import argparse
import math
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STARTS = (
    0, 150, 310, 465, 620, 775, 925, 1080, 1230, 1385, 1540, 1695,
    1850, 2005, 2160, 2315, 2475, 2635, 2790, 2945, 3100, 3260,
    3420, 3575, 3730, 3880, 4035, 4190, 4345.901,
)
CHUNK_SECONDS = 30
FPS = 8
# The drawn line is pale across all background colors. Keeping only bright,
# low-saturation strokes avoids needing a different chroma key at every cut.
VIDEO_FILTER = (
    "fps=8,crop=560:448:20:16,scale=400:320:flags=lanczos,"
    "format=gray,lut=y='if(lt(val,155),0,val)',"
    "format=rgba,colorkey=black:0.03:0.02"
)


def run(command):
    subprocess.run(command, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="local source video (not committed)")
    parser.add_argument("--only", type=int, choices=range(101, 129), metavar="101..128")
    parser.add_argument("--force", action="store_true", help="regenerate existing assets")
    args = parser.parse_args()
    if not args.source.is_file():
        parser.error(f"source not found: {args.source}")
    duration = float(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", str(args.source),
    ]))
    if abs(duration - STARTS[-1]) > 1:
        parser.error(f"expected the {STARTS[-1]:g}s compilation; source is {duration:g}s")
    output = ROOT / "episodes"
    output.mkdir(exist_ok=True)
    for index in range(28):
        number = 101 + index
        if args.only is not None and number != args.only:
            continue
        begin = STARTS[index]
        length = STARTS[index + 1] - begin
        print(f"Episode {number}: {begin:g}–{STARTS[index + 1]:g}s", flush=True)
        audio = output / f"{number}.ogg"
        if args.force or not audio.exists():
            run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-ss", str(begin),
                 "-t", str(length), "-i", str(args.source), "-vn", "-c:a", "libvorbis",
                 "-q:a", "3", "-y", str(audio)])
        for part in range(math.ceil(length / CHUNK_SECONDS)):
            frame_time = begin + part * CHUNK_SECONDS
            part_length = min(CHUNK_SECONDS, length - part * CHUNK_SECONDS)
            visual = output / f"{number}-{part:02d}.webp"
            if not args.force and visual.exists():
                continue
            run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-ss", str(frame_time),
                 "-t", str(part_length), "-i", str(args.source), "-vf", VIDEO_FILTER,
                 "-c:v", "libwebp_anim", "-lossless", "1", "-compression_level", "4",
                 "-loop", "0", "-an", "-y", str(visual)])


if __name__ == "__main__":
    main()
