class_name NakamaOpCode extends Node


# Op codes using for messages exchanged via Nakama connection.


enum enm {
	TRANSFER_FROM_LOBBY = 1,
	START_GAME = 2,
}


const _op_codes_reserved_for_host: Array = [
	NakamaOpCode.enm.TRANSFER_FROM_LOBBY,
	NakamaOpCode.enm.START_GAME,
]


# Checks whether message sender is valid. Some messages can
# only be sent by host. If a non-host client sends such
# messages, they should be ignored.
static func validate_message_sender(match_data: NakamaRTAPI.MatchData) -> bool:
	var sender_presence: NakamaRTAPI.UserPresence = match_data.presence

#	NOTE: sender_presence is null if message was sent by
#	server (match handler). Currently, there are no such
#	cases implemented but check this anyway just in case.
	if sender_presence == null:
		return true

	var sender_user_id: String = sender_presence.user_id
	var host_user_id: String = NakamaConnection.get_host_user_id()
	var sender_is_host: bool = sender_user_id == host_user_id

	var op_code: int = match_data.op_code
	var message_is_reserved_for_hosts: bool = _op_codes_reserved_for_host.has(op_code)

	var non_host_sent_reserved_message: bool = message_is_reserved_for_hosts && !sender_is_host

	if non_host_sent_reserved_message:
		push_error("Received invalid message reserved for host from non-host user: %s" % sender_user_id)

		return false

	return true
