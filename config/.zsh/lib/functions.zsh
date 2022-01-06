function ip() {
	echo $(ipconfig getifaddr en0)
}

function clean_downloads() {
	# :param duration: Filter downloads based on the file modification time in fd command such as "7 days".
	duration=$1
	fd -0 --changed-before "${duration}" --hidden . ~/Downloads | xargs -0 -I {} mv {} ~/.Trash
}
