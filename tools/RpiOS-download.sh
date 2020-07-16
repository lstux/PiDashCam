#!/bin/sh
MIRROR="https://downloads.raspberrypi.org"
DOWNLOAD_DIR=""
OUTPUT_FILE=""
IMAGE_TYPE=""
LINK_ONLY=false


usage() {
  exec >&2
  [ -n "${1}" ] && printf "Error : ${1}\n"
  printf "Usage : $(basename "${0}") [options]\n"
  printf "  Get Raspberry Pi OS image\n"
  printf "Options :\n"
  printf "  -d dir  : download image to dir/original_name\n"
  printf "  -o file : download image to file\n"
  printf "  -t      : only display download link\n"
  printf "  -f      : get full image (desktop+recommended)\n"
  printf "  -l      : get lite image\n"
  printf "  -h      : display this help message\n"
  exit 1
}

final_link() {
  curl -IL -o /dev/null -s -w "%{url_effective}\n" "${1}"
}

while getopts d:o:tflh opt; do case "${opt}" in
  d) DOWNLOAD_DIR="${OPTARG}";;
  o) OUTPUT_FILE="${OPTARG}";;
  t) LINK_ONLY=true;;
  f) [ -n "${IMAGE_TYPE}" ] && usage "multiples image types specified..."; IMAGE_TYPE="_full";;
  l) [ -n "${IMAGE_TYPE}" ] && usage "multiples image types specified..."; IMAGE_TYPE="_lite";;
  *) usage;;
esac; done

[ -n "${OUTPUT_FILE}" -a -n "${DOWNLOAD_DIR}" ] && usage "use only one of {-d dir|-o file}..."

LINK="${MIRROR}/raspios${IMAGE_TYPE}_armhf_latest"
REAL_LINK="$(curl -IL -o /dev/null -s -w "%{url_effective}" "${LINK}")"
if ${LINK_ONLY}; then
  printf "${REAL_LINK}\n"
  exit 0
fi

if ! [ -n "${OUTPUT_FILE}" ]; then
  [ -n "${DOWNLOAD_DIR}" ] || DOWNLOAD_DIR="$(pwd)"
  OUTPUT_FILE="${DOWNLOAD_DIR}/$(basename "${REAL_LINK}")"
fi
OUTPUT_FILE="$(realpath "${OUTPUT_FILE}")"

DOWNLOAD_DIR="$(dirname "${OUTPUT_FILE}")"
if ! [ -d "${DOWNLOAD_DIR}" ]; then
  while true; do
    read -p "Directory '${DOWNLOAD_DIR}' does not exist, create it? ([y]/n) " a
    case "${a}" in
      ""|y|Y) break;;
      n|N)    printf "Aborting...\n" >&2; exit 255;;
    esac
    printf "Please answer with 'y' or 'n'...\n"
    sleep 1
    printf "\n"
  done
  install -d -m755 "${DOWNLOAD_DIR}" || exit 2
fi

printf "Downloading to ${OUTPUT_FILE}...\n"
curl -o "${OUTPUT_FILE}" "${REAL_LINK}"

printf "To prepare SD card (eg: /dev/sdX) :\n"
printf "  unzip ${OUTPUT_FILE} -d ${DOWNLOAD_DIR} && \\ \n"
printf "  dd if=$(basename "${OUTPUT_FILE}" .zip).img of=/dev/sdX bs=4M status=progress conv=fsync\n"
printf "Or :\n"
printf "  unzip -p ${OUTPUT_FILE} | dd of=/dev/sdX bs=4M status=progress conv=fsync\n"
