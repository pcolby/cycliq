#!/bin/bash
#
# This script losslessly concatenates videos from Cycliq cameras.
# These cameras produce videos with two streams: H.264 video, and SOWT (PCM) audio.
# This script uses FFMPEG to join the videos such that the video streams are copied losslessly,
# but the audio streams are re-encoded to AAC, because FFMPEG doesn't support PCM audio in MP4.
#

set -euo pipefail

function require {
  local C;
  for c in "$@"; do
    if [ -v "${c^^}" ]; then continue; fi
    C=$(which "$c") || { echo "Required command not found: $c" >&2; exit 1; }
    declare -g ${c^^}="$C"
  done
}

require basename ffmpeg
[ "${SPEED_UP:-1}" -eq 1 ] || require bc ffprobe

[ $# -ge 3 ] || { echo "Usage: $("$BASENAME" "$BASH_SOURCE" .sh) in-file-1 in-file-2 [... in-file-n] out-file" >&2; exit 1; }

# Check that we can read/write the relevant files.
declare -a INPUT_FILES
while [ "$#" -gt 1 ]; do
  echo "Input: $1"
  [ -r "$1" ] || { echo "Input file not readable: $1" >&2; exit 2; }
  INPUT_FILES+=("$1"); shift
done

[ ! -e "$1" ] || { echo "Output file already exists: $1" >&2; exit 3; }
echo "Output: $1"
OUTPUT_FILE="$1"; shift
read -n1 -rp "Combine ${#INPUT_FILES[@]} input files [y,n]? " CONFIRMATION
[[ "$CONFIRMATION" =~ ^[Yy]$ ]] || exit
echo

# Setup speed-up flags (if relevant).
[ "${SPEED_UP:-1}" -eq 1 ] || {
  shopt -sq extglob
  printf -v EXPONENT '%.0f' $("$BC" -l <<< "l($SPEED_UP)/l(2)")
  printf -v AUDIO_FILTER 'atempo=2.0,%.0s' $(eval echo {1..$EXPONENT})
  printf -v VIDEO_FILTER 'tblend=average,framestep=2,%.0s' $(eval echo {1..$EXPONENT})
  PTS="0$("$BC" -l <<< "1/(2^$EXPONENT)")"
  AUDIO_FILTER="${AUDIO_FILTER:0:-1}"     # Trim the tailing ',' character.
  VIDEO_FILTER+="setpts=${PTS%%+(0)}*PTS" # Append the PTS.
  FRAME_RATE=$("$FFPROBE" -v warning -select_streams V -show_entries stream=r_frame_rate -of csv=p=0 -i "${INPUT_FILES[0]}" < /dev/null)
  echo "$EXPONENT|${PTS%%+(0)}|$AUDIO_FILTER|$VIDEO_FILTER|$FRAME_RATE"
}

# If writing to MP4, or using an audio filter then default to AAC-LC (see README.md for more information).
[[ "${OUTPUT_FILE##*.}" != 'mp4' && -z "${AUDIO_FILTER:-}" ]] ||
  : ${AUDIO_FLAGS:=-c:a aac -profile:a aac_low -b:a 384k}

# Concatenate input video streams a new file.
echo "$FFMPEG" -hide_banner -f concat -safe 0 -i \<\(printf "file %q\n" "${INPUT_FILES[@]}"\) \
  ${AUDIO_FLAGS:--c:a copy} ${AUDIO_FILTER:+-af $AUDIO_FILTER} \
  ${VIDEO_FILTER:+-vf} ${VIDEO_FILTER:--c:v copy} ${FRAME_RATE:+-r $FRAME_RATE} "$OUTPUT_FILE" \< /dev/null
"$FFMPEG" -hide_banner -f concat -safe 0 -i <(printf "file %q\n" "${INPUT_FILES[@]}") \
  ${AUDIO_FLAGS:--c:a copy} ${AUDIO_FILTER:+-af $AUDIO_FILTER} \
  ${VIDEO_FILTER:+-vf} ${VIDEO_FILTER:--c:v copy} ${FRAME_RATE:+-r $FRAME_RATE} "$OUTPUT_FILE" < /dev/null
