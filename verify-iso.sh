#!/usr/bin/env bash

# Ref for Bash Colors and formatting:
# https://misc.flogisoft.com/bash/tip_colors_and_formatting

function scan_iso_files() {
  S_B="\e[1m"
  S_U="\e[4m"
  S_BG_RED="\e[41m"
  S_BG_GREEN="\e[42m"
  S_FG_RED="\e[91m"
  S_FG_GREEN="\e[92m"
  S_FG_YELLOW="\e[93m"
  S_FG_RESET="\e[39m"
  S_RESET="\e[0m"
  MARK_CHECK="$S_FG_GREEN✔$S_FG_RESET"
  MARK_CROSS="$S_FG_RED✘$S_FG_RESET"
  MARK_WARN="$S_FG_YELLOW⚠️ $S_FG_RESET"

  # scan recursively (regardless ISO_DIR = iso or .) and case-insensitively "*.iso" files
  files=$(find $1 -type f -iname "*.iso")

  countBadFiles=0
  echo "Scanning ISO files…"
  for isoFile in $files; do
    read F N _ <<<"$(sudo filefrag $isoFile)"
    # COLOR=$([ "1" == "$N" ] && echo $S_BOLD || echo $S_BOLD$S_FG_RED)
    [ "1" == "$N" ] && {
      COLOR=""
      echo -e " $MARK_CHECK $COLOR$isoFile$S_RESET: contiguous ($N fragement found)"
    } || {
      COLOR="$S_B$S_BG_RED"
      countBadFiles=$((countBadFiles + 1))
      echo -e " $MARK_CROSS $COLOR$isoFile$S_RESET: non-contiguous ($N fragements found)"
    }
  done
  [ "0" == $countBadFiles ] && echo "Done… $MARK_CHECK all checked files are contiguous!" || echo -e "Done… found 2 non-bootable ISO files.\n$MARK_WARN Please 'Delete+re-Copy' or 'Defrag' them!"
}

scan_iso_files .
