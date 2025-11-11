
function mkdir-date () {
	local date_prefix input sanitized dir_name
	date_prefix=$(date "+%Y-%m-%d")
	read -r "?Directory description: " input
	sanitized=${${input}// /-}
	if [[ -n $sanitized ]]; then
		dir_name="${date_prefix}-${sanitized}"
	else
		dir_name="$date_prefix"
	fi
	mkdir "$dir_name"
}
