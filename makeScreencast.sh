#!/bin/bash
#------------------------------------------------------------------------
# This script requires the following DEB packages:
#
#   alsa-utils, x11-utils, ffmpeg, sox
#
# You'll first need to run this command, to create a noise profile:
#
#   sox -q -c 1 -d /tmp/_tempfile_.wav noiseprof > "$HOME/.screencast-noise.prof"
#
# Then wait for about 30 seconds to a minute, and be as silent as you can, allowing
# for all of the standards static and noise to play, such as computer fans.
#
# This command will remove the temporary file created above:
#
#   rm /tmp/_tempfile_.wav
#-----------------------------------------------------------------------

mksc(){
	printf "Recording audio and video -- type 'q' to quit...\n"
	
	(
		local MAILPATH='/dev/null'
		printf -v DATE "%(%F_%X)T" -1
		local DIR="$HOME/Videos/MKSC"
		local FNV="$DIR/screencast-video-$DATE.mp4"
		local FNA="$DIR/screencast-audio-$DATE.wav"
		local FNAT="$DIR/screencast-audio-$DATE.tmp.wav"
		local SNP="$HOME/.screencast-noise.prof"
		local TMP=`mktemp --suffix='.wav'`

		if [ -z "$RES" ]; then
			local LINE RES
			while read -a LINE; do
				if [ "${LINE[0]}" == '-geometry' ]; then
					RES=${LINE[1]%+*+*}
					break
				fi
			done <<< "$(xwininfo -root)"
		fi

		[ -z "$RES" ] && return 1
		[ -d "$DIR" ] || mkdir -vp "$DIR"

		arecord -q -D default -r 44100 -f cd -t wav "$FNAT" &
		local AR_PID=$!

		ffmpeg -y -loglevel 16 -f x11grab -s "$RES" -framerate 60\
			-i "${DISPLAY:-:0.0}" -vcodec mpeg4 -b:v 60000k\
			-threads 12 -preset veryfast -crf 22 "$FNV" || return 1

		kill -s SIGINT $AR_PID || return 1

		sox -q -c 1 -t wav "$FNAT" "$FNA" noisered\
			"$SNP" 0.23 2> /dev/null || return 1

		rm -v "$FNAT" || return 1

		ffmpeg -y -loglevel 16 -i "$FNV" -i "$FNA" -acodec libvorbis\
			-b:a 128k -ac 1 -ar 44100 "${FNV/-video}" || return 1

		rm -v "$FNV" "$FNA" || return 1

		sync "${FNV/-video}" || return 1
	)
}
