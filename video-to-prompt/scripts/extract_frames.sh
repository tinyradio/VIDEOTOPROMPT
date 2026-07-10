#!/usr/bin/env bash
# Extract timestamped frames from a video for AI analysis.
# Usage: extract_frames.sh <video> <output_dir> [max_frames] [start_sec] [duration_sec]
#   max_frames   default 60 — sampling interval widens automatically for long videos
#   start_sec    optional — extract from this offset (for zooming into a range)
#   duration_sec optional — extract only this many seconds
set -euo pipefail

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg not found. Install with: brew install ffmpeg" >&2
  exit 1
fi

VIDEO="${1:?usage: extract_frames.sh <video> <output_dir> [max_frames] [start_sec] [duration_sec]}"
OUT="${2:?output_dir required}"
MAX_FRAMES="${3:-60}"
START="${4:-0}"
DUR="${5:-}"

[ -f "$VIDEO" ] || { echo "ERROR: video not found: $VIDEO" >&2; exit 1; }
mkdir -p "$OUT"
rm -f "$OUT"/frame_*.jpg "$OUT/manifest.txt"

TOTAL=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO")
TOTAL=${TOTAL%.*}
if [ -n "$DUR" ]; then SPAN="$DUR"; else SPAN=$(( TOTAL - START )); fi
[ "$SPAN" -ge 1 ] || SPAN=1

# 1 frame per second by default; widen the interval so long videos stay under MAX_FRAMES
if [ "$SPAN" -le "$MAX_FRAMES" ]; then
  INTERVAL=1
else
  INTERVAL=$(( (SPAN + MAX_FRAMES - 1) / MAX_FRAMES ))
fi
FPS="1/$INTERVAL"

SS_ARGS=(); [ "$START" != "0" ] && SS_ARGS=(-ss "$START")
DUR_ARGS=(); [ -n "$DUR" ] && DUR_ARGS=(-t "$DUR")

# ${arr[@]+...} keeps `set -u` happy on macOS bash 3.2 when the array is empty
ffmpeg -hide_banner -loglevel error ${SS_ARGS[@]+"${SS_ARGS[@]}"} -i "$VIDEO" ${DUR_ARGS[@]+"${DUR_ARGS[@]}"} \
  -vf "fps=$FPS,scale='min(768,iw)':-2" -q:v 3 "$OUT/frame_%04d.jpg"

N=$(ls "$OUT"/frame_*.jpg 2>/dev/null | wc -l | tr -d ' ')
[ "$N" -ge 1 ] || { echo "ERROR: no frames extracted" >&2; exit 1; }

{
  echo "video: $VIDEO"
  echo "total_duration_sec: $TOTAL"
  echo "extracted_frames: $N"
  echo "interval_sec: $INTERVAL"
  echo "range_start_sec: $START"
  echo ""
  for f in "$OUT"/frame_*.jpg; do
    idx=$((10#$(basename "$f" .jpg | cut -d_ -f2)))
    ts=$(( START + (idx - 1) * INTERVAL ))
    printf "%s -> %02d:%02d (t=%ds)\n" "$(basename "$f")" $((ts/60)) $((ts%60)) "$ts"
  done
} > "$OUT/manifest.txt"

cat "$OUT/manifest.txt"
