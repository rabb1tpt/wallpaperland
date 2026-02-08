# Wallpaperland 🖼️

**Independent** wallpaper picker for Hyprland with terminal UI (fzf + kitty preview).

*Inspired by [waypaper](https://github.com/anufrievroman/waypaper) but fully standalone.*

## Features

- 🔍 **Automatically finds wallpapers** from multiple directories
- 👀 **Live image preview** in terminal (using kitty)
- ⚡ **Fuzzy search** - just type to filter (using fzf)
- 📁 **Clean filenames** - no long paths cluttering the view
- 💾 **Remembers** current wallpaper
- ⌨️ **Independent** - uses `swaybg` directly, no GUI dependencies

## What about waypaper?

[Waypaper](https://github.com/anufrievroman/waypaper) is a great **GUI alternative** with thumbnails and vim keybindings.

**wallpaper-picker.sh is completely independent** - you can use either:
- This script (terminal-based, lightweight)
- Waypaper (GUI-based, more visual)
- Both (install both and choose your preference)

They both use `swaybg` as the backend but are otherwise separate tools.

## Installation

### Required

**wallpaper-picker.sh** only needs:
```bash
# Ubuntu/Debian
sudo apt install swaybg

# Arch
paru -S swaybg
```

You also need (probably already installed):
- `fzf` - fuzzy finder
- `kitty` - terminal with image support

### Optional: Install waypaper GUI

If you also want the GUI option:

```bash
# Ubuntu/Debian
pipx install waypaper

# Arch
paru -S waypaper
```

### Quick install script

Install everything (swaybg + waypaper):
```bash
cd ~/Bruno/code/wallpaperland
./install-wallpaper.sh
```

Or terminal-only (skip waypaper):
```bash
./install-wallpaper.sh --terminal-only
```

## Usage

### Option 1: GUI (waypaper)

```bash
waypaper
```

First time:
1. Click "Choose Folder" and select `~/Pictures/wallpaper`
2. Browse thumbnails
3. Click wallpaper to set it

### Option 2: Terminal (wallpaper-picker.sh)

```bash
~/Bruno/code/wallpaperland/wallpaper-picker.sh
```

Must run in `kitty` terminal for preview!

### Add Hyprland keybindings

Add to `~/Bruno/code/dotfiles/hyprland/hyprland.conf`:

```
# Wallpaper picker (GUI)
bind = $mainMod, W, exec, waypaper

# Wallpaper picker (Terminal)
bind = $mainMod SHIFT, W, exec, kitty -e ~/Bruno/code/wallpaperland/wallpaper-picker.sh
```

Then reload: `hyprctl reload`

- **SUPER + W** = GUI picker
- **SUPER + SHIFT + W** = Terminal picker

## How it works

### GUI (waypaper)
1. Open waypaper
2. Browse wallpaper thumbnails
3. Click to set wallpaper
4. Optional: Use vim keys (h/j/k/l) to navigate

### Terminal (wallpaper-picker.sh)
1. Press the keybinding (or run the script)
2. Browse wallpapers with arrow keys or fuzzy search
3. Preview appears on the right side
4. Press ENTER to set wallpaper
5. Press ESC to cancel

## Tips

### waypaper
- Saves wallpaper on restart
- Supports multiple monitors
- Can handle GIFs and videos (with mpvpaper)

### wallpaper-picker.sh
- Type to search: start typing part of the filename
- Use arrow keys to navigate
- Preview updates in real-time
- Current wallpaper is saved to `~/.config/current-wallpaper`

## Adding more wallpaper directories

Edit `wallpaper-picker.sh` and add to the `WALLPAPER_DIRS` array:

```bash
WALLPAPER_DIRS=(
    "$HOME/Pictures/wallpaper"
    "$HOME/code/Wallpaper-Bank/wallpapers"
    "$HOME/your/new/directory"  # Add here
)
```

## Troubleshooting

### No wallpaper backend found

Run the install script:
```bash
cd ~/Bruno/code/wallpaperland
./install-wallpaper.sh
```

Or install manually:
```bash
paru -S swaybg
```

### waypaper not opening

Make sure it's installed:
```bash
which waypaper
paru -S waypaper
```

### Terminal preview not showing

Make sure you're running in `kitty` terminal. The script will still work without preview.

### Wallpaper doesn't persist after reboot

waypaper automatically saves wallpaper state. For manual script, you can restore with:
```bash
# Add to Hyprland config
exec-once = swaybg -i $(cat ~/.config/current-wallpaper) -m fill
```
