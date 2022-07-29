# shellcheck shell=sh

. ./vk_api.sh

HANDLERS=""

flatten_json() (
	jq_flatten='
		paths(scalars) as $path | 
		{"key" : $path | join("_"), "value" : getpath($path)} | 
		"\(.key)=\(.value)"
	'
	echo "$1" | jq -c "$jq_flatten"
)

export_json() {
	old_IFS=$IFS 
	IFS="
"	
	for keyval in $(flatten_json "$1"); do
		keyval="${keyval#?}"
		keyval="${keyval%%?}"
		#keyval=$(printf "%b" "$keyval")

		export "$keyval"
	done

	IFS=$old_IFS
}

add_handler() {
	HANDLERS="$HANDLERS $1"
}

run_bot () {
	bots_long_poll | while read -r event; do (
		export_json "$event"

		for handler in $HANDLERS; do
			"$handler" "$event"
		done
	) & done
}
