#!/usr/bin/env bash
# Wallpaper Picker for Hyprland
# Interactive wallpaper selection with preview

set -euo pipefail

# Log directory and file
LOG_DIR="$HOME/.cache/wallpaper-picker-logs"
LOG_FILE="$LOG_DIR/wallpaper-picker-$(date '+%Y-%m-%d').log"
SWAYBG_LOG="$LOG_DIR/swaybg-$(date '+%Y-%m-%d').log"
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Clean up old log files (keep last 7 days)
cleanup_old_logs() {
    find "$LOG_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true
}

# Run cleanup on start
cleanup_old_logs

log "=== Wallpaper Picker Started ==="

# Wallpaper directories
WALLPAPER_DIRS=(
    "$HOME/Pictures/wallpaper"
    "$HOME/code/Wallpaper-Bank/wallpapers"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find all wallpapers
find_wallpapers() {
    for dir in "${WALLPAPER_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null
        fi
    done
}

# Set wallpaper using available backend
set_wallpaper() {
    local wallpaper="$1"
    log "set_wallpaper called with: $wallpaper"

    # Check if file exists
    if [[ ! -f "$wallpaper" ]]; then
        log "ERROR: Wallpaper file not found: $wallpaper"
        echo -e "${RED}✗ Wallpaper file not found: $wallpaper${NC}"
        return 1
    fi
    log "File exists, proceeding..."

    if command -v swaybg &> /dev/null; then
        log "Using swaybg backend"
        # Kill existing swaybg instances
        pkill swaybg 2>/dev/null || true
        log "Killed existing swaybg instances"

        log "Starting swaybg with: $wallpaper"
        # Start swaybg with output redirected to log
        nohup swaybg -i "$wallpaper" -m fill >> "$SWAYBG_LOG" 2>&1 &
        local swaybg_pid=$!
        log "swaybg started with PID: $swaybg_pid, output: $SWAYBG_LOG"

        # Give it a moment to start
        sleep 0.5

        # Check if it's still running
        if kill -0 "$swaybg_pid" 2>/dev/null; then
            log "swaybg is running (verified)"
            echo -e "${GREEN}✓ Wallpaper set with swaybg${NC}"
        else
            log "ERROR: swaybg process died immediately, check $SWAYBG_LOG"
            echo -e "${RED}✗ swaybg failed to start${NC}"
            echo -e "${YELLOW}Check logs: $SWAYBG_LOG${NC}"
            return 1
        fi
    elif command -v hyprctl &> /dev/null; then
        log "Using hyprctl backend"
        # Fallback: use hyprctl to set via hyprpaper or preload
        log "Running: hyprctl hyprpaper preload $wallpaper"
        if hyprctl hyprpaper preload "$wallpaper" 2>&1 | tee -a "$LOG_FILE"; then
            log "Preload successful"
        else
            log "WARNING: Preload failed or not available"
        fi

        log "Running: hyprctl hyprpaper wallpaper ,$wallpaper"
        if hyprctl hyprpaper wallpaper ",$wallpaper" 2>&1 | tee -a "$LOG_FILE"; then
            log "Wallpaper set successful"
            echo -e "${GREEN}✓ Wallpaper set with hyprctl${NC}"
        else
            log "ERROR: Failed to set wallpaper with hyprctl"
            echo -e "${RED}✗ Failed to set wallpaper with hyprctl${NC}"
            return 1
        fi
    else
        log "ERROR: No wallpaper backend found"
        echo -e "${RED}✗ No wallpaper backend found!${NC}"
        echo -e "${YELLOW}Install one of: swaybg or hyprpaper${NC}"
        echo -e "${YELLOW}Run: ~/Bruno/code/wallpaperland/install-wallpaper.sh${NC}"
        exit 1
    fi

    # Save current wallpaper to state file
    log "Saving wallpaper path to state file"
    echo "$wallpaper" > "$HOME/.config/current-wallpaper"
    log "State file updated"
}

# Preview function for fzf
preview_wallpaper() {
    local file="$1"
    if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then
        # Use kitty's image viewer
        kitty +kitten icat --clear --transfer-mode=memory --stdin=no --place=80x40@0x0 "$file"
    else
        # Fallback: show file info
        echo "File: $file"
        echo "Size: $(du -h "$file" | cut -f1)"
        echo "Dimensions: $(identify -format '%wx%h' "$file" 2>/dev/null || echo 'N/A')"
    fi
}

# Export function for fzf
export -f preview_wallpaper

# Main
main() {
    log "main() function started"
    echo -e "${GREEN}Wallpaper Picker${NC}"
    echo -e "${YELLOW}Debug log: $LOG_FILE${NC}"
    echo "Finding wallpapers..."

    # Find all wallpapers
    log "Searching for wallpapers in: ${WALLPAPER_DIRS[*]}"
    wallpapers=$(find_wallpapers | sort)

    if [[ -z "$wallpapers" ]]; then
        log "ERROR: No wallpapers found"
        echo -e "${RED}No wallpapers found!${NC}"
        exit 1
    fi

    count=$(echo "$wallpapers" | wc -l)
    log "Found $count wallpapers"
    echo -e "${GREEN}Found $count wallpapers${NC}"
    echo ""

    # Create temp directory for lookup
    tmpdir=$(mktemp -d)

    # Create symlinks with basenames pointing to full paths
    while IFS= read -r path; do
        basename=$(basename "$path")
        linkname="$basename"

        # Handle duplicate basenames by appending parent dir
        if [[ -e "$tmpdir/$linkname" ]]; then
            parent=$(basename "$(dirname "$path")")
            linkname="${parent}__${basename}"
        fi

        # Create symlink
        ln -sf "$path" "$tmpdir/$linkname"
    done <<< "$wallpapers"

    # Use fzf to select wallpaper with preview (show basenames)
    log "Starting fzf selection from tmpdir: $tmpdir"
    log "Files in tmpdir: $(ls "$tmpdir" | wc -l) files"

    selected_basename=$(cd "$tmpdir" && ls | sort | fzf \
        --height=100% \
        --preview="kitty +kitten icat --clear --transfer-mode=memory --stdin=no --place=80x40@0x0 {}" \
        --preview-window=right:60% \
        --prompt="Select wallpaper: " \
        --header="Press ENTER to set, ESC to cancel" \
        --border \
        --margin=1 \
        --padding=1) || {
            log "fzf exited with code $?, no selection made"
            selected_basename=""
        }

    log "fzf returned, selected_basename='$selected_basename'"

    # Get full path from symlink
    if [[ -n "$selected_basename" ]]; then
        log "Resolving symlink for: $selected_basename"
        selected=$(readlink -f "$tmpdir/$selected_basename")
        log "Resolved to full path: $selected"

        # Verify the symlink exists
        if [[ ! -e "$tmpdir/$selected_basename" ]]; then
            log "ERROR: Symlink does not exist: $tmpdir/$selected_basename"
        fi
    else
        selected=""
        log "No selection made (empty selected_basename)"
    fi

    # Clean up temp directory
    log "Cleaning up tmpdir: $tmpdir"
    rm -rf "$tmpdir"

    if [[ -n "$selected" ]]; then
        echo ""
        echo -e "${YELLOW}Setting wallpaper...${NC}"
        log "Calling set_wallpaper with: $selected"
        if set_wallpaper "$selected"; then
            echo ""
            echo -e "${GREEN}✓ Done!${NC}"
            echo "Current wallpaper: $selected"
            log "Wallpaper set successfully"
            log "=== Wallpaper Picker Completed Successfully ==="
        else
            log "ERROR: set_wallpaper failed"
            log "=== Wallpaper Picker Failed ==="
            echo -e "${RED}✗ Failed to set wallpaper${NC}"
            echo -e "${YELLOW}Check log file: $LOG_FILE${NC}"
            exit 1
        fi
    else
        log "No wallpaper selected, exiting"
        log "=== Wallpaper Picker Exited (No Selection) ==="
        echo -e "${YELLOW}No wallpaper selected${NC}"
        exit 0
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
