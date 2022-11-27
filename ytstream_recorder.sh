#!/bin/bash

# Original script
# https://old.reddit.com/r/Hololive/comments/jjhiby/afk_archiving_an_unarchived_livestream_linux/gacz7o4/

# Ordered by priority, in this case 1080p60, 1080p, 720p60, 720p, 480p, 360p, 240p, 144p
FORMATS=(301 96 300 95 94 93 92 91)

# Seconds before trying again
SLEEPSECS=60

# You may need to change this if your locale is not English, not my problem
NOT_LIVE_STR="This live event will begin in "

FNAME="ytstream.mkv"

DOTHING=1
while [ $DOTHING -eq 1 ]; do
	STR=""
	for FORMAT in "${FORMATS[@]}"; do
		LIVE_CHECK=$(yt-dlp -F $1 2>&1)
		if [[ $LIVE_CHECK =~ $NOT_LIVE_STR ]]; then
			WHEN=$(echo $LIVE_CHECK | sed -n -e "s/^.*$NOT_LIVE_STR//p")
			echo "Stream only starts in $WHEN.."
			break
		fi

		STR=$(yt-dlp -o is_live -f $FORMAT -g $1)

		if [ -z "${STR}" ]; then
			echo "Format $FORMAT unavailable"
			continue
		else
			DOTHING=0
			echo "Using format $FORMAT"

			NEW_NAME=$(yt-dlp --skip-download --print filename -o "%(channel)s - %(title)s [%(id)s]" $1)
			if [ ! -z "${NEW_NAME}" ]; then
				FNAME="$NEW_NAME.mkv"
			else
				DATE=$(date "+%Y-%m-%d_%H-%M-%S_")
				FNAME="$DATE$FNAME"
			fi
			break
		fi

	done
	if [ $DOTHING -eq 1 ]; then
		echo "Stream $1 not live, trying again in $SLEEPSECS seconds..."
		sleep $SLEEPSECS
	fi
done

echo "Storing stream thumbnail and info..."
yt-dlp --write-thumbnail --convert-thumbnails png --write-info-json --skip-download -o "%(channel)s - %(title)s [%(id)s].%(ext)s" $1

echo "Output filename: $FNAME"
echo "Downloading $1"
ffmpeg -i "${STR}" -c copy -loglevel panic "$FNAME"
echo "Done"
