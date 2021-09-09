#!/bin/bash

SOURCE=${1:-"/System/Library/Fonts/Apple Color Emoji.ttc"}
OUT=${2:-"./AppleColorEmoji.ttf"}

XNAME="./AppleColorEmoji-vx.ttx"
X2NAME="./AppleColorEmoji-v2.ttx"
XGNAME="./AppleColorEmoji-GSUB.ttx"
FFMNAME="./AppleColorEmoji-morx.ttf"
FFGNAME="./AppleColorEmoji-GSUB.ttf"

LIGATURES="./ligatures.xml" # don't change, it's referened in a2a.py

FONTFORGE_EXECUTABLE="fontforge"

# brew cask installs here, so maybe that's an option:
if [ -f "/Applications/FontForge.app/Contents/Resources/opt/local/bin/fontforge" ]; then
  FONTFORGE_EXECUTABLE="/Applications/FontForge.app/Contents/Resources/opt/local/bin/fontforge"
fi

# check prereqs
command -v ttx >/dev/null 2>&1 || { echo >&2 "🙅 Hi! You need to install ttx (via fonttools)."; exit 1; }
command -v xmlstarlet >/dev/null 2>&1 || { echo >&2 "🙅 Hi! You need to install xmlstarlet."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo >&2 "🙅 Hi! You need to install python3."; exit 1; }
command -v "${FONTFORGE_EXECUTABLE}" >/dev/null 2>&1 || { echo >&2 "🙅 Hi! You need to install fontforge. I tried checking if you have the GUI app, but can't find it either."; exit 1; }

# check input
if [ ! -f "${SOURCE}" ]; then
  echo "📛 Hi! I can't find the input file at: ${SOURCE}"
  exit 9
fi

function finish {
  rm -f "${XNAME}"
  rm -f "${X2NAME}"
  rm -f "${XGNAME}"
  rm -f "${FFMNAME}"
  rm -f "${FFGNAME}"

  rm -f "${LIGATURES}"

  echo "finishing!"
}
trap finish EXIT

# clear out existing output
rm -f "${OUT}"

# STEP 1: convert ligatures from <morx> to <GSUB> via FontForge

# FontForge doesn't support <morx> version 3, so we need to rewrite to appear as version 2
# ref: https://github.com/fontforge/fontforge/blob/b08b1902e059a85c2d62236fa2070e924ca44ff2/fontforge/parsettfatt.c#L4768
#
# version 3 adds an additional table for "Subtable Glyph Coverage Array" that (seemingly) can be safely ignored
# ref: https://github.com/harfbuzz/harfbuzz/blob/37379f8f7d6dab83b011416b8c7ff25d4f7365a0/src/hb-aat-layout-morx-table.hh#L1091
#
# we'll use `ttx` for this, as it would require rewriting checksums etc. we don't require `sbix` binary, so drop it for now
ttx -o "${XNAME}" -y 0 -x sbix "${SOURCE}"

xmlstarlet ed -u '/ttFont/morx/Version/@value' -v '2' "${XNAME}" > "${X2NAME}"

ttx -o "${FFMNAME}" "${X2NAME}"

# export Apple's font in a non-Apple format (note: this will drop all the bitmaps, but we still have the glyph references/ligatures/etc)
"${FONTFORGE_EXECUTABLE}" -script ./export-ligatures.pe "${FFMNAME}" "${FFGNAME}"

# export the new font to XML
ttx -o "${XGNAME}" "${FFGNAME}"

# strip out everything but the ligature information: GDEF, GPOS, GSUB
xmlstarlet ed -d "/ttFont/*[not((name()='GDEF') or (name()='GPOS') or (name()='GSUB'))]" "${XGNAME}" > "${LIGATURES}"

# STEP 2: merge <GSUB> information into existing font

# convert the font using an external script
python3 ./a2a.py "${SOURCE}" "${OUT}"

echo

if [ -f "${OUT}" ]; then
  echo "✅ Success!"
  echo "Hi! You have a freshly baked emoji font: ${OUT} 🎂"
else
  echo "💀 Something went wrong, and I'm not sure what."
fi