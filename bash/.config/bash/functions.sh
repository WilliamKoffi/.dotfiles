. $LOG_MESSAGE_PATH

# todo -- daily TODO file manager.
#
# The implementation lives in Nim at ~/.dotfiles/scripts/todo (this
# repository is public, so the compiled binary is never committed). This
# function is only a bootstrap: it makes sure ~/.local/bin/todo exists and
# is not older than the source, then hands over to it.

__todo_build() {
	local src_dir="$1" bin="$2"
	local build_dir="${XDG_CACHE_HOME:-$HOME/.cache}/todo-build"

	if ! command -v nim >/dev/null 2>&1; then
		print_message error "nim is required to build todo but is not on PATH"
		return 1
	fi

	print_message info "building todo from $src_dir"
	mkdir -p "$build_dir" "$(dirname "$bin")" || return 1

	if ! (cd "$src_dir" && TODO_BUILD_DIR="$build_dir" \
		nim c -d:release --hints:off --outdir:"$build_dir" src/todo.nim); then
		print_message error "failed to build todo"
		return 1
	fi

	install -m 755 "$build_dir/todo" "$bin" || return 1
	print_message success "installed todo to $bin"
}

__todo_ensure_binary() {
	local src_dir="$1" bin="$2"

	# Missing binary: first run.
	[[ -x "$bin" ]] || { __todo_build "$src_dir" "$bin"; return $?; }

	# Stale binary: any source file newer than it. -quit stops at the first
	# hit, so this is a couple of stat calls in the common case.
	if [[ -n "$(find "$src_dir/src" "$src_dir/todo.nimble" "$src_dir/config.nims" \
		-type f -newer "$bin" -print -quit 2>/dev/null)" ]]; then
		__todo_build "$src_dir" "$bin"
		return $?
	fi

	return 0
}

todo() {
	local bin="$HOME/.local/bin/todo"
	local src_dir="$HOME/.dotfiles/scripts/todo"

	__todo_ensure_binary "$src_dir" "$bin" || return 1

	# --help and --version answer a question and run nothing; moving the
	# shell out from under someone who only asked for the usage text is a
	# surprise, so those invocations leave the cwd alone.
	local arg query=0
	for arg in "$@"; do
		case "$arg" in
		-h | --help | -v | --version) query=1 ;;
		esac
	done

	"$bin" "$@"
	local status=$?

	# The binary chdir's into the todos directory itself, so the editor opens
	# there. That cannot reach the parent shell, though, and the old Bash
	# implementation left the shell in the todos directory too -- hence this.
	if [[ $query -eq 0 ]]; then
		cd "$HOME/lab/temp/todos" 2>/dev/null
	fi

	return $status
}

unalias ll 2>/dev/null
ll() {
	if [ "$#" -eq 0 ]; then
		eza -lah
		return
	fi

	if [ -e "$1" ] && [ "$#" -eq 1 ]; then
		eza -lah -- "$1"
		return
	fi

	local resolved
	resolved="$(zoxide query "$@" 2>/dev/null)" || resolved="$*"

	echo "$resolved"
	eza -lah -- "$resolved"
}

kebab_case() {
	local input_string="$1"
	echo "$input_string" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -d '"'
}

nvim() {
	folder=$(basename "$PWD")
	echo -ne "\033]0;nvim/$folder\007"
	command nvim "$@"
}

function boltdiy_dev() {
	cd /opt/bolt.diy || {
		echo "Directory /opt/bolt.diy not found."
		return 1
	}

	if [[ "$1" == "install" ]]; then
		pnpm install
	fi

	pnpm run dev
}
