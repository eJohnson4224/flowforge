#!/usr/bin/env bash
set +e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI_PATH="$ROOT_DIR/flowforge/flowforge/elektroid-cli"
DEST_DIR="$ROOT_DIR/flowforge/flowforge"

if [[ ! -f "$CLI_PATH" ]]; then
  echo "Missing elektroid-cli at $CLI_PATH" >&2
  touch "${SCRIPT_OUTPUT_FILE_0:-/tmp/bundle-elektroid.stamp}" 2>/dev/null || true
  exit 0
fi

# Collect deps (Homebrew paths), including transitive dependencies.
declare -a QUEUE
declare -a ALL_DEPS
declare -a SEEN_PATHS
declare -a COPY_BASES
declare -a COPY_PATHS

QUEUE+=("$CLI_PATH")
for lib in "$DEST_DIR"/*.dylib; do
  [[ -e "$lib" ]] || continue
  QUEUE+=("$lib")
done

collect_deps() {
  otool -L "$1" | tail -n +2 | awk '{print $1}' | grep -E '^/opt/homebrew|^/usr/local' || true
}

has_value() {
  local needle="$1"
  shift
  local candidate
  for candidate in "$@"; do
    [[ "$candidate" == "$needle" ]] && return 0
  done
  return 1
}

copy_map_has() {
  local base="$1"
  has_value "$base" "${COPY_BASES[@]}"
}

copy_map_add() {
  COPY_BASES+=("$1")
  COPY_PATHS+=("$2")
}

while [[ ${#QUEUE[@]} -gt 0 ]]; do
  item="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")
  [[ -f "$item" ]] || continue
  has_value "$item" "${SEEN_PATHS[@]}" && continue
  SEEN_PATHS+=("$item")
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    ALL_DEPS+=("$dep")
    base=$(basename "$dep")
    if ! copy_map_has "$base"; then
      copy_map_add "$base" "$dep"
    fi
    has_value "$dep" "${SEEN_PATHS[@]}" || QUEUE+=("$dep")
  done < <(collect_deps "$item")
done

if [[ ${#ALL_DEPS[@]} -eq 0 ]]; then
  echo "No Homebrew deps found for elektroid-cli." >&2
  touch "${SCRIPT_OUTPUT_FILE_0:-/tmp/bundle-elektroid.stamp}" 2>/dev/null || true
  exit 0
fi

# Copy deps
for i in "${!COPY_BASES[@]}"; do
  base="${COPY_BASES[$i]}"
  dep="${COPY_PATHS[$i]}"
  [[ -f "$dep" ]] || continue
  cp -f "$dep" "$DEST_DIR/$base" || true
  chmod u+w "$DEST_DIR/$base" || true
  echo "Copied $base"
done

# Rewrite load paths for CLI and bundled dylibs
for target in "$CLI_PATH" "$DEST_DIR"/*.dylib; do
  [[ -e "$target" ]] || continue
  for dep in "${ALL_DEPS[@]}"; do
    depbase=$(basename "$dep")
    install_name_tool -change "$dep" "@executable_path/$depbase" "$target" || true
  done
done

# Rewrite dylib ids
for lib in "$DEST_DIR"/*.dylib; do
  [[ -e "$lib" ]] || continue
  base=$(basename "$lib")
  install_name_tool -id "@executable_path/$base" "$lib" || true
done

touch "${SCRIPT_OUTPUT_FILE_0:-/tmp/bundle-elektroid.stamp}" 2>/dev/null || true

echo "Bundling complete."
exit 0
