#!/usr/bin/env bash
# Deletes the saved game state so the next run starts from starting_level_path.
# Usage: tools/clear_save.sh [--all]   (--all also removes player_config.cfg)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
project="$root/project.godot"

setting() {
	grep -m1 "^$1=" "$project" | sed -E 's/^[^=]+=//; s/^"(.*)"$/\1/' || true
}

save_file="$(grep -m1 'SAVE_STATE_PATH' "$root/addons/maaacks_game_template/base/nodes/state/global_state.gd" \
	| sed -E 's/.*"user:\/\/([^"]+)".*/\1/')"
save_file="${save_file:-global_state.tres}"

case "$(uname -s)" in
	Darwin) data="$HOME/Library/Application Support" ;;
	MINGW* | MSYS* | CYGWIN*) data="$(cygpath -u "$APPDATA")" ;;
	*) data="${XDG_DATA_HOME:-$HOME/.local/share}" ;;
esac

if [[ "$(setting config/use_custom_user_dir)" == "true" ]]; then
	name="$(setting config/custom_user_dir_name)"
	[[ -n "$name" ]] || name="$(setting config/name)"
	dir="$data/$name"
else
	godot_dir="Godot"
	[[ "$(uname -s)" == Linux* ]] && godot_dir="godot"
	dir="$data/$godot_dir/app_userdata/$(setting config/name)"
fi

files=("$dir/$save_file")
[[ "${1:-}" == "--all" ]] && files+=("$dir/player_config.cfg")

for f in "${files[@]}"; do
	if [[ -f "$f" ]]; then
		rm "$f"
		echo "Removed $f"
	else
		echo "Not found: $f"
	fi
done
