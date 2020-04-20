#!/bin/bash
# Using named pipes to avoid intermediate files
# http://trac.ffmpeg.org/wiki/Concatenate#samecodec

set -euo pipefail

mkfifo temp6 temp7 temp8 temp9 temp10 temp11 temp12 temp13 temp14

ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0006.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp6  2> /dev/null & \
ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0007.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp7  2> /dev/null & \
ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0008.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp8  2> /dev/null & \
ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0009.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp9  2> /dev/null & \
ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0010.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp10 2> /dev/null & \
ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0011.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp11 2> /dev/null & \
ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0012.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp12 2> /dev/null & \
ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0013.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp13 2> /dev/null & \
ffmpeg -y -i /media/paul/disk2/DCIM/100_CF12/CYQ_0014.MP4 -c copy -bsf:v h264_mp4toannexb -f mpegts temp14 2> /dev/null & \
ffmpeg -f mpegts -i "concat:temp6|temp7|temp8|temp9|temp10|temp11|temp12|temp13|temp14" -c copy -bsf:a aac_adtstoasc /home/paul/media/videos/cycliq/output.mp4
