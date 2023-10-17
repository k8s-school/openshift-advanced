scw_version="v2.19.0"
scw() {
    docker run -it --rm -v $HOME/.config/scw:/root/.config/scw -v $HOME/.ssh:/root/.ssh scaleway/cli:"$scw_version" "$@"
}

_scw() {
	_get_comp_words_by_ref -n = cword words

	output=$(docker run -i --rm -v $HOME/.config/scw:/root/.config/scw scaleway/cli:"$scw_version" autocomplete complete bash -- "$COMP_LINE" "$cword" "${words[@]}")
	COMPREPLY=($output)
	# apply compopt option and ignore failure for older bash versions
	[[ $COMPREPLY == *= ]] && compopt -o nospace 2> /dev/null || true
	return
}
complete -F _scw scw
