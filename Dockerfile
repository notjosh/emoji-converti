FROM ubuntu:latest
WORKDIR /workdir
ENV DEBIAN_FRONTEND noninteractive

RUN apt update
RUN apt --yes install fontforge fonttools python3-fonttools xmlstarlet

COPY ./src /src

CMD ["/src/convert.sh", "/assets/Apple Color Emoji.ttc", "/assets/AppleColorEmoji.ttf"]