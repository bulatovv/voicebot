#!/bin/sh

set -o xtrace

. ./.config
. ./handlers.sh

setup_storage() (
	[ -d "$STORAGE" ] || mkdir "$STORAGE"
	[ -d "$STORAGE/videos" ] || mkdir "$STORAGE/videos"

	for file in videos/*; do
		[ -f "$STORAGE/$file" ] || cp "$file" "$STORAGE/videos"
	done

)



add_handler voice_handler 

setup_storage && run_bot
