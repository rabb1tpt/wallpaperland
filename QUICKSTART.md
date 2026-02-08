# Quick Start Guide

## 1. Install (one-time setup)

```bash
cd ~/Bruno/code/wallpaperland
./install-wallpaper.sh
```

This installs `waypaper` (GUI) + `swaybg` (backend).

## 2. Pick a wallpaper

### GUI (recommended)

```bash
waypaper
```

First time:
1. Click "Choose Folder"
2. Navigate to `~/Pictures/wallpaper` or `~/code/Wallpaper-Bank/wallpapers`
3. Click wallpaper to set it

### Terminal (with preview)

```bash
~/Bruno/code/wallpaperland/wallpaper-picker.sh
```

**Must run in kitty terminal** for image preview!

## 3. Add Hyprland keybindings (optional)

Edit your Hyprland config:

```bash
nano ~/Bruno/code/dotfiles/hyprland/hyprland.conf
```

Add these lines near the other keybindings:

```
# Wallpaper pickers
bind = $mainMod, W, exec, waypaper
bind = $mainMod SHIFT, W, exec, kitty -e ~/Bruno/code/wallpaperland/wallpaper-picker.sh
```

Then reload: `hyprctl reload`

Now:
- **SUPER + W** = Open GUI picker
- **SUPER + SHIFT + W** = Open terminal picker

---

## Usage Tips

### waypaper (GUI)
- Click wallpaper to set
- Use vim keys: h/j/k/l to navigate
- Wallpaper persists after reboot

### wallpaper-picker.sh (Terminal)
- **Arrow keys**: Navigate
- **Type**: Fuzzy search by filename
- **ENTER**: Set wallpaper
- **ESC**: Cancel

That's it! 🎨
