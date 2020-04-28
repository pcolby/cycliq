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

# Choose default audio options (see README.md for more information).
[ "${OUTPUT_FILE##*.}" != 'mp4' ] || : ${AUDIO_FLAGS:=-c:a aac -profile:a aac_low -b:a 384k}
: ${AUDIO_FLAGS:=-c:a copy}

# Concatenate input video streams a new file.
echo "$FFMPEG" -hide_banner -f concat -safe 0 -i \<\(printf "file %q\n" "${INPUT_FILES[@]}"\) ${AUDIO_FLAGS:-} -c:v copy "$OUTPUT_FILE"
"$FFMPEG" -hide_banner -f concat -safe 0 -i <(printf "file %q\n" "${INPUT_FILES[@]}") ${AUDIO_FLAGS:-} -c:v copy "$OUTPUT_FILE"
