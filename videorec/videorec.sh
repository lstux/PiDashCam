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
OUTFILE=""

RECLENGTH=0

REQUIRED_PACKAGES="ffmpeg v4l-utils alsa-utils"

for f in ~/.videorec.conf /etc/videorec.conf; do
  [ -e "${f}" ] || continue
  source "${f}" && break
done


usage() {
  exec >&2
  printf "Usage : $(basename "${0}") [options]\n"
  printf "  Record video stream\n"
  printf "options :\n"
  printf "  -v device : specify video device [${VIDEO_DEVICE}]\n"
  printf "  -a device : specify audio device [${AUDIO_DEVICE}]\n"
  printf "  -l length : record at most length seconds [unlimited]\n"
  printf "  -o file   : save to file [${OUTDIR}/${OUTPFX}XXXXXX${OUTEXT}]\n"
  printf "  -h        : display this help message\n"
  exit 1
}

get_outfilename() {
  local vid
  if ! [ -d "${OUTDIR}" ]; then
    install -d -m755 "${OUTDIR}" || return 1
    vid=1
  else
    vid="$(ls "${OUTDIR}/${OUTPFX}"*"${OUTEXT}" | tail -n1 | sed -e "s/^${OUTPFX}//" -e "s/${OUTEXT}\$//")"
    vid="$(expr ${vid} + 1)"
  fi
  printf "${OUTDIR}/${OUTPFX}%06d${OUTEXT}\n" ${vid}
}

audio_opts() {
  [ -n "${AUDIO_DEVICE}" ] || return 0
  printf -- " -f alsa -i ${AUDIO_DEVICE}"
  [ "${AUDIO_CHANNELS}" = "stereo" ] && printf -- " -ac 2" || printf -- " -ac 1"
  [ -n "${AUDIO_CODEC}" ] && printf -- " -acodec ${AUDIO_CODEC}"
  [ -n "${AUDIO_SAMPLERATE}" ] && printf -- " -ar ${AUDIO_SAMPLERATE}"
  [ -n "${AUDIO_BITRATE}" ] && printf -- " -ab ${AUDIO_BITRATE}"
}

start_rec() {
  local f="${1}"
  avconv $(audio_opts) -f video4linux2 -i ${VIDEODEV} "${f}"
}

while getopts v:a:l:o:h opt; do case "${opt}" in
  v) VIDEODEV="${OPTARG}";;
  a) AUDIODEV="${OPTARG}";;
  l) [ ${OPTARG} -ge 0 ] 2>/dev/null || usage; RECLENGTH="${OPTARG}";;
  o) OUTFILE="${OPTARG}";;
  *) usage;;
esac; done
shift $(expr ${OPTIND} - 1)
[ -n "${1}" ] && usage
