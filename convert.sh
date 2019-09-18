#!/bin/bash

SOURCE=${1:-"/System/Library/Fonts/Apple Color Emoji.ttc"}
OUT=${2:-"./AppleColorEmoji.ttf"}

FFNAME="./AppleColorEmoji-fontforged.ttf"
XFFNAME="./AppleColorEmoji-fontforged.ttx"

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
  rm -f "${FFNAME}"
  rm -f "${XFFNAME}"
}
trap finish EXIT

# clear out existing output
rm -f "${OUT}"

# export Apple's font in a non-Apple format (note: this will drop all the bitmaps, but we still have the glyph references/ligatures/etc)
"${FONTFORGE_EXECUTABLE}" -script ./export-ligatures.pe "${SOURCE}(Apple Color Emoji)" "${FFNAME}"

# export the new font to XML
ttx -o "${XFFNAME}" "${FFNAME}"

# strip out everything but the ligature information: GDEF, GPOS, GSUB
xmlstarlet ed -d "/ttFont/*[not((name()='GDEF') or (name()='GPOS') or (name()='GSUB'))]" "${XFFNAME}" > ./ligatures.xml

# convert the font using an external script
python3 ./a2a.py "${SOURCE}" "${OUT}"

echo

if [ -f "${OUT}" ]; then
  echo "✅ Success!"
  echo "Hi! You have a freshly baked emoji font: ${OUT} 🎂"
else
  echo "💀 Something went wrong, and I'm not sure what."
fi