function qemu_test_launch() {
	local ARCH="x86_64"
	local qemu_args=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-a|--arch)
				ARCH="$2"
				shift 2
				;;
			*)
				qemu_args+=("$1")
				shift
				;;
		esac
	done

	local id
	id=$(date +%s%N)
	local mon_sock="/tmp/qemu-mon-$id.sock"
	local qemu_bin="qemu-system-$ARCH"

	if ! command -v "$qemu_bin" &> /dev/null; then
		echo "Error $qemu_bin not found" >&2
		return 1
	fi

	$qemu_bin -monitor unix:"$mon_sock",server,nowait "${qemu_args[@]}" >/dev/null 2>&1 &

	while [ ! -e "$mon_sock" ]; do
		sleep 1;
	done
	echo "$id"
}

function qemu_test_quit() {
	local id="$1"
	local mon_sock="/tmp/qemu-mon-$id.sock"

	if [ ! -e "$mon_sock" ]; then
		echo "Error socket $mon_sock not found" >&2
		return 1
	fi

	echo "quit" | socat -t 0.1 - UNIX-CONNECT:"$mon_sock" > /dev/null 2>&1
	sleep 0.1
}

function qemu_test_write() {
	local id="$1"
	local text="$2"
	local mon_sock="/tmp/qemu-mon-$id.sock"

	if [ ! -e "$mon_sock" ]; then
		echo "Error socket $mon_sock not found" >&2
		return 1
	fi

	for (( i=0; i<${#text}; i++ )); do
		local char="${text:$i:1}"
		local key=""

		case "$char" in
			" ") key="spc" ;;
			$'\n') key="ret" ;;
			$'\t') key="tab" ;;
			"-") key="minus" ;;
			"=") key="equal" ;;
			"[") key="bracket_left" ;;
			"]") key="bracket_right" ;;
			"\\") key="backslash" ;;
			";") key="semicolon" ;;
			"'") key="apostrophe" ;;
			",") key="comma" ;;
			".") key="dot" ;;
			"/") key="slash" ;;
			"<") key="shift-comma" ;;
			">") key="shift-dot" ;;
			"?") key="shift-slash" ;;
			"!") key="shift-1" ;;
			"@") key="shift-2" ;;
			"#") key="shift-3" ;;
			"$") key="shift-4" ;;
			"%") key="shift-5" ;;
			"^") key="shift-6" ;;
			"&") key="shift-7" ;;
			"*") key="shift-8" ;;
			"(") key="shift-9" ;;
			")") key="shift-0" ;;
			"_") key="shift-minus" ;;
			"+") key="shift-equal" ;;
			"{") key="shift-bracket_left" ;;
			"}") key="shift-bracket_right" ;;
			"|") key="shift-backslash" ;;
			":") key="shift-semicolon" ;;
			'"') key="shift-apostrophe" ;;
			[a-z0-9]) key="$char" ;;
			[A-Z]) key="shift-${char,,}" ;;
			*) key="$char" ;;
		esac

		echo "sendkey $key" | socat -t 0.1 - UNIX-CONNECT:"$mon_sock" > /dev/null 2>&1
		sleep 0.1
	done
}

function qemu_test_read() {
	local id="$1"
	local mon_sock="/tmp/qemu-mon-$id.sock"
	local screen_dump="/tmp/qemu-screen-$id.ppm"

	if [ ! -e "$mon_sock" ]; then
		echo "Error socket $mon_sock not found" >&2
		return 1
	fi

	if [ -e "$screen_dump" ]; then
		rm "$screen_dump"
	fi

	echo "screendump $screen_dump" | socat -t 0.1 - UNIX-CONNECT:"$mon_sock" > /dev/null 2>&1

	if [ ! -f "$screen_dump" ]; then
		echo "Error screendump creation failed" >&2
		return 1
	fi

	tesseract "$screen_dump" stdout 2> /dev/null
}

function qemu_test_wait_for() {
	local id="$1"
	local text="$2"
	local sleeptime=${3:-1}
	local timeout=${4:-300}

	local deadline=$((SECONDS + timeout))

	while ! qemu_test_read "$id" | grep --quiet "$text"; do
		if [ "$SECONDS" -ge "$deadline" ]; then
			return 1;
		fi
		sleep "$sleeptime";
	done

}

function qemu_test_login() {
	local id="$1"
	local login="$2"
	local password="$3"

	qemu_test_wait_for "$id" "login" 5

	qemu_test_write "$id" "$login"
	qemu_test_write "$id" $'\n'

	qemu_test_wait_for "$id" "Password"

	qemu_test_write "$id" "$password"
	qemu_test_write "$id" $'\n'

}

function qemu_test_run_command() {
	local id="$1"
	local command="$2"

	qemu_test_write "$id" "$command"
	qemu_test_write "$id" $'\n'
	qemu_test_wait_for "$id" "root@"
}
