. $LOG_MESSAGE_PATH

todo() {
	local todo_dir=~/lab/tmp/todos/
	cd "$todo_dir" 2>/dev/null || {
		print_message error "Failed to change directory to $todo_dir"
		return 1
	}
	local today_file="TODO.$(date +%Y%m%d).md"
	local yesterday_file="TODO.$(date -d "yesterday" +%Y%m%d).md"

	# If today's file exists, just open it
	if [[ -f "$today_file" ]]; then
		print_message info "Today's TODO file already exists."
		nvim "$today_file"
		return 0
	fi

	# Function to clean TODO
	clean_todo() {
		awk '
		NR<=2 { print; next }   # always keep first two lines

		/^## / {
		  if (keep) printf "%s", section
		  section=$0 ORS
		  keep=0
		  next
		}

		/^- \[x\]/ { next }   # skip completed tasks

		/^- \[ \]/ {
		  section = section $0 ORS
		  keep=1
		  next
		}

		{
		  section = section $0 ORS
		}

		END {
		  if (keep) printf "%s", section
		}
		' "$1" | sed ':a;/^\n*$/{$d;N;ba}'
	}

	# If yesterday’s file exists, clean it into today’s
	if [[ -f "$yesterday_file" ]]; then
		print_message info "found $yesterday_file"
		clean_todo "$yesterday_file" >"$today_file"
	else
		# Otherwise use the latest file
		local latest_file=$(ls -t TODO.*.md 2>/dev/null | head -n 1)
		if [[ -n "$latest_file" ]]; then
			print_message info "found $latest_file"
			clean_todo "$latest_file" >"$today_file"
		else
			print_message info "No TODO files found. Creating an empty TODO file."
			touch "$today_file"
		fi
	fi

	nvim "$today_file"
}

kebab_case() {
	local input_string="$1"
	echo "$input_string" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -d '"'
}

nvim() {
	folder=$(basename "$PWD")
	echo -ne "\033]0;nvim/$folder\007"
	/usr/bin/nvim "$@"
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
