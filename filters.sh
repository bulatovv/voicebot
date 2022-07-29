# shellcheck shell=sh

# TODO: add filters for all event types
message_new() {
	[ "$type" = "message_new" ]
	return $?
}


for_me() {
	[ "$object_message_text" != "${object_message_text#"[club$GROUP_ID|@$NAME]"}" ] &&
		return 0	
	[ "$object_message_peer_id" = "$object_message_from_id" ] &&
		return 0
	return 1
}
