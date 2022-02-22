#!/bin/sh

SOURCE=${1:-"/System/Library/Fonts/Apple Color Emoji.ttc"}

# check input
if [ ! -f "${SOURCE}" ]; then
  echo "📛 Hi! I can't find the input file at: ${SOURCE}"
  exit 9
fi

cp "${SOURCE}" ./assets/

docker build -t local/emoji-converti .
docker run -v "${PWD}"/assets:/assets local/emoji-converti