#!/bin/sh

VIDEO_DEVICE="/dev/video0"   # Get list with v4l2-ctl --list-devices
# Get list of supported formats with v4l2-ctl --list-formats-ext -d ${VIDEO_DEVICE}

AUDIO_DEVICE="hw:1"      # Get list with arecord -l
AUDIO_CODEC="libmp3lame" # Audio codec
AUDIO_CHANNELS="mono"    # mono/stereo
AUDIO_SAMPLERATE="22500" # Sample rate in Hertz
AUDIO_BITRATE="128k"     # Default bitrate

OUTDIR="/home/pi/videorec"
OUTPFX="vd_"
OUTEXT=".avi"


chkpack() {
  local bin="${1}" pack="${2}" p
  [ -n "${pack}" ] || pack="${bin}"
  printf "Checking for ${bin} : "
  p="$(which ${bin} 2>/dev/null)"
  [ -x "${p}" ] && { printf "${p}\n"; return 0; }
  printf "missing\n"
  MISSING="${MISSING} ${pack}"
  return 1
}

select_videodev() {
  local devdesc="$(v4l2-ctl --list-devices)" devices l d i s
  devices="$(echo "${devdesc}" | sed -n 's/^\s*\(\/dev\/video[0-9]\+\)$/\1/p')"
  if [ -z "${devices}" ]; then
    printf "No video capture device available...\n" >&2
    return 1
  fi
  if [ $(echo "${devices}" | wc -l) -eq 1 ] 2>/dev/null; then
    printf "Only one video capture device available, autoselecting '" >&2
    echo "${devdesc}" | while read l; do printf "${l} "; done >&2
    printf "'\n" >&2
    echo ${devices}
    return 0
  fi
  while true; do
    i=0
    printf "Select a video device :\n" >&2
    for d in ${devices}; do
      i=$(expr ${i} + 1)
      desc="$(echo "${devdesc}" | grep -B1 "${d}" | head -n1)"
      printf "${i}) %s %s\n" "${desc}" "${d}" >&2
    done
    read -p " (1-${i}) > " s
    if [ ${s} -ge 1 -a ${s} -le ${i} ] 2>/dev/null; then
      echo "${devices}" | sed -n ${s}p
      break
    fi
    printf "Please enter a number between 1 and ${i}...\n" >&2
    sleep 1
    printf "\n"
  done
}

select_audiodev() {
  local devices="$(arecord -l | sed -n '/^card/p')" nbdev i s
  if [ -z "${devices}" ]; then
    printf "No audio capture device available...\n" >&2
    return 1
  fi
  nbdev="$(echo "${devices}" | wc -l)"
  if [ ${nbdev} -eq 1 ] 2>/dev/null; then
    printf "Only one audio capture device available, autoselecting '${devices}'\n" >&2
    echo "${devices}" | sed 's/^card \([0-9]\+\): .*, device \([0-9]\+\): .*/hw:\1:\2/'
    return 0
  fi
  while true; do
    printf "Select an audio device :\n" >&2
    for i in $(seq 1 ${nbdev}); do
      printf "${i}) %s\n" "$(echo "${devices}" | sed -n ${i}p)" >&2
    done
    read -p " (1-${nbdev}) > " s
    if [ ${s} -ge 1 -a ${s} -le ${nbdev} ] 2>/dev/null; then
      echo "${devices}" | sed -n -e 's/^card \([0-9]\+\): .*, device \([0-9]\+\): .*/hw:\1:\2/' -e ${s}p
      break
    fi
    printf "Please enter a number between 1 and ${nbdev}...\n" >&2
    sleep 1
    printf "\n"
  done
}

[ "$(id -un)" = "root" ] || { printf "Please run this script as root (eg: via sudo)\n" >&2; exit 1; }

#Check for needed packages (ffmpeg, v4l-utils, alsa-utils)
MISSING=""
chkpack ffmpeg
chkpack v4l2-ctl v4l-utils
chkpack arecord alsa-utils
if [ -n "${MISSING}" ]; then
  printf "Following packages seems not installed (or binaries are not in PATH) :\n" >&2
  printf " ${MISSING}\n" >&2
  if which apt >/dev/null 2>&1; then
    printf "Installing via apt...\n"
    apt -y install ${MISSING} || exit 2
  else
    printf "These packages are required, please install first!\n" >&2
    exit 2
  fi
fi

#Select VIDEO_DEVICE
VIDEO_DEVICE="$(select_videodev)"

#Select AUDIO_DEVICE
AUDIO_DEVICE="$(select_audiodev)"

#Select default OUTDIR
