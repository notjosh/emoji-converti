# Let's Make Apple Emoji Work on Linux!

There a handful of "bitmap in font" standards - embedded bitmaps at various sizes, embedded SVGs, etc. Our goal is to convert the Apple font into something that can be read by Chrome and/or Firefox on Linux systems.

# Running

There are two modes of running:

1. With Docker
1. Without Docker

## With Docker

As long as you have a copy of the emoji font (say, `Apple Color Emoji.ttc`), then you can run:

```shell
./run-in-docker.sh [/path/to/input/file]
```

After the image builds and runs, you should get a finished file in `assets/AppleColorEmoji.ttf`.

## Without Docker

Note: I've only tested this on macOS directly, but the Docker image runs on Ubuntu so should theoretically work elsewhere.

### Prerequisites

- `fontforge`
- `ttx` (part of `fonttools`)
- `xmlstarlet`
- Python 3, with `pip install fonttools`

Defaults assume you're using macOS, but it's not necessary.

### Usage

```shell
./convert.sh [/path/to/input/file] [/path/to/output/file]
```

The input file is expected to be an instance of `Apple Color Emoji.ttc`, and will probably break in weird ways on other fonts.

The default args (if run simply with `./convert.sh`) will read from `/System/Library/Fonts/Apple Color Emoji.ttc` and output to `./AppleColorEmoji.ttf`.

# Background

## How Emoji Fonts Can Work

OpenType has a handful of sanctioned extensions:

- Apple's `sbix` ([doc](https://docs.microsoft.com/en-gb/typography/opentype/spec/sbix)): Works on macOS/iOS. Embedded PNG/JPEG/TIFF.
- Google's `CBLC`/`CBDT` ([`CBLC` doc](https://docs.microsoft.com/en-gb/typography/opentype/spec/cblc)/[`CBDT` doc](https://docs.microsoft.com/en-gb/typography/opentype/spec/cbdt)): Works on Android, but supported in Linux. Embedded uncompressed BMP/compressed PNG.
- Microsoft's `COLR`/`CPAL` ([`COLR` doc](https://docs.microsoft.com/en-gb/typography/opentype/spec/colr)/[`CPAL` doc](https://docs.microsoft.com/en-gb/typography/opentype/spec/cpal)): (multi-)coloured glyphs
- `SVG`/`CPAL` ([`SVG` doc](https://docs.microsoft.com/en-gb/typography/opentype/spec/svg)/[`CPAL` doc](https://docs.microsoft.com/en-gb/typography/opentype/spec/cpal)): Embedded SVG with (multi-)colour palette.

Our only real viable option here is to convert `sbix` to `CBLC`/`CBDT`. Frustratingly similar, but also different. Hooray for standards!

## Considerations

Emojis make use of ligatures (i.e. person emoji + skin tone, or blank flag + colour), so we need to make sure we retain those mappings.

Apple uses `mort` (deprecated) or `morx` to define their ligatures (part of AAT, not OpenType), so we'll want to convert them to `GDEF` and `GSUB` definitions to make use of them.

## Strategy

1. Extract ligature information (using `fontforge` and `ttx`)
1. Convert PNG tables (using `a2a.py`)
1. Convert & inject ligature information (using `xmlstarlet` and `a2a.py`)
1. Write our result to a file!

# Prior Art

The heavy lifting here is done via [`a2a.py`](https://gist.github.com/angelsl/cd2aea8ea74027217e97). I updated it to include dynamic/external ligature information, and to run on Python 3.
