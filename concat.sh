#!/bin/bash
#
# This script uses names pipes for losslessly concatenate videos. It's optimised for videos from
# Cycliq cameras. These cameras produce videos with two streams: H.264 video, and SOWT (PCM) audio.
# This script uses FFMPEG to join the videos such that the video streams are copied losslessly,
# but the audio streams are re-encoded to AAC, because FFMPEG doesn't support PCM audio in MP4.
#
# See https://trac.ffmpeg.org/wiki/Concatenate#Usingnamedpipestoavoidintermediatefiles

set -euo pipefail

# Default to YouTube's recommendations; ie AAC-LC at 384 kbps (for stereo).
# See https://support.google.com/youtube/answer/1722171?hl=en
: ${AUDIO_FLAGS:=-c:a aac -profile:a aac_low -b:a 384k}

function require {
  local C;
  for c in "$@"; do
    if [ -v "${c^^}" ]; then continue; fi
    C=$(which "$c") || { echo "Required command not found: $c" >&2; exit 1; }
    declare -g ${c^^}="$C"
  done
}

require basename ffmpeg mkfifo mktemp

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

# Stream input videos to FIFO pipes, in MPEG-TS format
TMP_DIR=$("$MKTEMP" -dt "$("$BASENAME" "$BASH_SOURCE" .sh).XXX")
declare FIFO_PIPES=
for INPUT_FILE in "${INPUT_FILES[@]}"; do
  FIFO_PIPE=$("$MKTEMP" -up "$TMP_DIR" fifo.XXX)
  "$MKFIFO" "$FIFO_PIPE"
  echo "$FFMPEG" -y -i "$INPUT_FILE" ${AUDIO_FLAGS:-} -c:v copy -bsf:v h264_mp4toannexb -f mpegts "$FIFO_PIPE" -v warning \&
  "$FFMPEG" -y -i "$INPUT_FILE" ${AUDIO_FLAGS:-} -c:v copy -bsf:v h264_mp4toannexb -f mpegts "$FIFO_PIPE" -v warning &
  FIFO_PIPES="$FIFO_PIPES|$FIFO_PIPE"
done

# Concatenate input video streams a new file.
echo "$FFMPEG" -f mpegts -i "concat:${FIFO_PIPES#|}" -c copy -bsf:a aac_adtstoasc "$OUTPUT_FILE"
"$FFMPEG" -f mpegts -i "concat:${FIFO_PIPES#|}" -c copy -bsf:a aac_adtstoasc "$OUTPUT_FILE"
