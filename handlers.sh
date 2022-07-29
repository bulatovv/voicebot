# shellcheck shell=sh

. ./core.sh
. ./filters.sh

extract_voices() ( 
	echo "$1" | jq -rc '
		[.object.message | .. | .attachments? // empty | .[] | 
		select(.type? == "audio_message") | .audio_message.link_mp3] | 
		unique | @tsv
	'
)

download_voices() (
	label="$1"; shift

	i=1
	filenames=""
	for link_mp3 in "$@"; do
		filename="${label}-${i}.mp3"
		curl -sS "$link_mp3" -o "$filename"
		filenames="$filenames $filename"
	done

	echo "$filenames"
)

pick_random() (
	rnd=$(od -vAn -N2 -tu2 < /dev/urandom)
	result=$(("$rnd" % $# + 1))

	eval echo \$$result
)

pick_video() (
	for token in $1; do
		case "$token" in
			*сабвэй*|*с[её]рф*|*subway*|*surf*)
				video="$STORAGE/videos/subway_surf.mp4"
				;;
			*мужик*|*чипсы*)
				video="$STORAGE/videos/мужик_чипсы.mp4"
				;;
		esac
	done

	[ "$video" ] && echo "$video" ||
		pick_random "$STORAGE/videos/"*
)

build_ffmpeg_params() (
	input=$1; shift

	i=1
	params="-loglevel error -i $input"
	for file in "$@"; do
		params="${params} -i ${file}"
		i=$((i+1))
	done
	
	params="${params} -map 0:v:0"
	
	i=1
	while [ $i -le $# ]; do
		params="${params} -map ${i}:a:0"
		i=$((i+1))
	done

	params="${params} -c:v copy -shortest"
	
	echo "$params"
)

process_video() (
	input="$1"; shift
	name="$1"; shift
	# shellcheck disable=SC2046
	ffmpeg $(build_ffmpeg_params "$input" "$@") "$name"
)

upload_video() (
	upload_url=$(
		VK_TOKEN="$USER_TOKEN"
		vk_api video.save is_private=1 group_id="$GROUP_ID" | jq -rc '.upload_url'
	)

	curl -s -F video_file=@"$1" "$upload_url"
)


voice_handler() (
	for_me && message_new || return

	voices=$(extract_voices "$1")
	[ "$voices" ] || return
	
	# shellcheck disable=SC2086
	downloaded=$(download_voices "$STORAGE/$event_id" $voices)

	output="${STORAGE}/${event_id}-result.mp4"
	input=$(pick_video "$object_message_text")

	# shellcheck disable=SC2086
	process_video "$input" "$output" $downloaded

	response=$(upload_video "$output")

	video_id=$(echo "$response" | jq -rc '.video_id')
	owner_id=$(echo "$response" | jq -rc '.owner_id')

	vk_api messages.send 								   \
		peer_id="$object_message_peer_id" 				   \
		attachment="video${owner_id}_${video_id}" 		   \
		random_id=0										   \
		> /dev/null
		#reply_to="$object_message_conversation_message_id" \

	# shellcheck disable=SC2086
	rm "$output" $downloaded
)
