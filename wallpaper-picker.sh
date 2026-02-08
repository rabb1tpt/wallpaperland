#!/usr/bin/env bash
# Wallpaper Picker for Hyprland
# Interactive wallpaper selection with preview

set -euo pipefail

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

    if command -v swaybg &> /dev/null; then
        # Kill existing swaybg instances
        pkill swaybg 2>/dev/null || true
        swaybg -i "$wallpaper" -m fill &
        disown
        echo -e "${GREEN}✓ Wallpaper set with swaybg${NC}"
    elif command -v hyprctl &> /dev/null; then
        # Fallback: use hyprctl to set via hyprpaper or preload
        hyprctl hyprpaper preload "$wallpaper" 2>/dev/null || true
        hyprctl hyprpaper wallpaper ",$wallpaper" 2>/dev/null || true
        echo -e "${GREEN}✓ Wallpaper set with hyprctl${NC}"
    else
        echo -e "${RED}✗ No wallpaper backend found!${NC}"
        echo -e "${YELLOW}Install one of: swaybg or hyprpaper${NC}"
        echo -e "${YELLOW}Run: ~/Bruno/code/wallpaperland/install-wallpaper.sh${NC}"
        exit 1
    fi

    # Save current wallpaper to state file
    echo "$wallpaper" > "$HOME/.config/current-wallpaper"
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
    echo -e "${GREEN}Wallpaper Picker${NC}"
    echo "Finding wallpapers..."

    # Find all wallpapers
    wallpapers=$(find_wallpapers | sort)

    if [[ -z "$wallpapers" ]]; then
        echo -e "${RED}No wallpapers found!${NC}"
        exit 1
    fi

    count=$(echo "$wallpapers" | wc -l)
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
    selected_basename=$(cd "$tmpdir" && ls | sort | fzf \
        --height=100% \
        --preview="kitty +kitten icat --clear --transfer-mode=memory --stdin=no --place=80x40@0x0 {}" \
        --preview-window=right:60% \
        --prompt="Select wallpaper: " \
        --header="Press ENTER to set, ESC to cancel" \
        --border \
        --margin=1 \
        --padding=1)

    # Get full path from symlink
    if [[ -n "$selected_basename" ]]; then
        selected=$(readlink -f "$tmpdir/$selected_basename")
    else
        selected=""
    fi

    # Clean up temp directory
    rm -rf "$tmpdir"

    if [[ -n "$selected" ]]; then
        echo ""
        echo -e "${YELLOW}Setting wallpaper...${NC}"
        set_wallpaper "$selected"
        echo ""
        echo -e "${GREEN}✓ Done!${NC}"
        echo "Current wallpaper: $selected"
    else
        echo -e "${YELLOW}No wallpaper selected${NC}"
        exit 0
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
