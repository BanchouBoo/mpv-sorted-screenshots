# mpv-sorted-screenshots

Simple script to sort screenshots based on file names and nested directories

## How it works

Consider the following:
- You have `screenshot-dir` set to `/home/boo/pictures/mpv`
- You have `screenshot-format` set to `png`
- You are playing a video file at `/home/boo/videos/tv/bungo/thumpus.mkv`
- You are 5 minutes, 32 seconds, and 231 miliseconds in the file

At different nested directory levels a screenshot would save at:
- 0: `/home/boo/pictures/mpv/thumpus.mkv/05:32.231.png`
- 1: `/home/boo/pictures/mpv/bungo/thumpus.mkv/05:32.231.png`
- 2: `/home/boo/pictures/mpv/tv/bungo/thumpus.mkv/05:32.231.png`
- 3: `/home/boo/pictures/mpv/videos/tv/bungo/thumpus.mkv/05:32.231.png`

And so on.

## Usage

Bind `script-message sorted-screenshot` to a key. Any argument that works for `screenshot-to-file` also works here (e.g. `script-message sorted-screenshot window` would include the OSD in the screenshot)

Example
```
s script-message sorted-screenshot
S script-message sorted-screenshot video # without subtitles
Ctrl+s script-message sorted-screenshot window # with OSD
```

You can set the script option `nested-directory-level` to set the amount of nesting in the final screenshot path, defaults to 1.

## Caveats

Currently doesn't work on network files, those will fall back to mpv's regular screenshotting behavior. They will work in the future.
