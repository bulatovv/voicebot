# shellcheck shell=sh

panic() {
	echo "$1" >&2 ; exit 1
}

warning() {
	echo "$1" >&2
}

vk_api() (
	set -- "$@" "access_token=${VK_TOKEN}" "v=${VERSION}"
	method="$1"; shift
	args=$(IFS='&'; echo "$*")

	if result=$(curl -sS -X POST --data "$args" "https://api.vk.com/method/${method}" 2>&1)
	then
		echo "$result" | 
			jq -rc ".response, .error.error_code, .error.error_msg" | (
				read -r response
				read -r error_code
				read -r error_msg

				[ "$error_code" != null ] &&
					panic "VK_API_ERROR[${error_code}]: ${error_msg}"

				echo "$response"
		)
	else
		panic "CURL_ERROR[$?]: $(echo "$result" | cut -d' ' -f3)"
	fi

)

bots_long_poll() (
    vk_api groups.getLongPollServer group_id="$GROUP_ID" |
        jq -rc '.key,.server,.ts' | (
			read -r key
			read -r server
			read -r ts

			while true; do

				if ! answ=$(curl -sS "${server}?act=a_check&key=${key}&ts=${ts}&wait=25" 2>&1)
				then
					warning "$answ"
					sleep 1
					continue
				fi
				
				failed=$(echo "$answ" | jq -rc '.failed')
				case "$failed" in
					null)
						echo "$answ" | jq -rc '.updates | .[]'
						;;
					2 | 3)
						answ=$(vk_api groups.getLongPollServer group_id="$GROUP_ID")
						key=$(echo "$answ" | jq -rc '.key')
						;;
				esac
				
				ts=$(echo "$answ" | jq -rc ".ts")
			done
		)
)
