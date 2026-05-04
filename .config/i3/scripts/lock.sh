#!/bin/bash
TIMECOLOR="FFFFFF"
TIMEFONT="San Francisco"
TIMESIZE=60
TIMESTYLE="%H:%M:%S"
DATECOLOR="FFFFFF"
DATEFONT="Space Age"
DATESIZE=25
DATESTYLE="%A, %d %b"
# Ring Colors
VERIFYING_INSIDE="FFFFFF44"
WRONG_INSIDE="FF000044"
INSIDE="00000000"
LINE="00000000"
KEYPRESS="FFFFFFFF"
BACKSPACEPRESS="CCCCCCFF"
RINGCOLOR="F7045DFF"
RINGVERIFYINGCOLOR="FFFFFFFF"
RINGWRONGCOLOR="00000000"
RINGTEXTSIZE=14
RINGRADIUS=45

i3lock -t -i $HOME/.config/i3/scripts/sunrise.jpg -knf --force-clock \
--time-color="$TIMECOLOR" --layout-align 1 --time-align 1 \
--time-font="$TIMEFONT" --date-color="$DATECOLOR" --time-pos="x+120:h-95" \
--date-size="$DATESIZE" --time-size="$TIMESIZE" --date-str="$DATESTYLE" -e \
--date-font="$DATEFONT" --date-align 1 \
--insidever-color="$VERIFYING_INSIDE" --insidewrong-color="$WRONG_INSIDE" \
--inside-color="$INSIDE" --line-color="$LINE" --keyhl-color="$KEYPRESS" \
--bshl-color="$BACKSPACEPRESS" --ring-color="$RINGCOLOR" \
--ringver-color="$RINGVERIFYINGCOLOR" --ringwrong-color="$RINGWRONGCOLOR" \
--separator-color="$KEYPRESS" --ind-pos="x+68:h-105.5" --radius="$RINGRADIUS" \
--modif-size=1  --time-str="$TIMESTYLE" --verif-text="" --wrong-text=""
# --indicator circle does not disappear
# $HOME/.rand_bg.png
