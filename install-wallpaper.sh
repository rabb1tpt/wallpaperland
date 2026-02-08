#!/usr/bin/env bash
# Install swaybg backend and optionally waypaper GUI for Hyprland

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
INSTALL_WAYPAPER=true
if [[ "${1:-}" == "--terminal-only" ]]; then
    INSTALL_WAYPAPER=false
fi

echo -e "${GREEN}Wallpaper Setup for Hyprland${NC}"
echo ""
if [[ "$INSTALL_WAYPAPER" == false ]]; then
    echo -e "${BLUE}Terminal-only mode: Installing swaybg only${NC}"
    echo ""
fi

# Detect package manager
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    echo -e "${BLUE}Detected: Ubuntu/Debian (apt)${NC}"
elif command -v pacman &> /dev/null; then
    # Check for AUR helper on Arch
    if command -v paru &> /dev/null; then
        PKG_MANAGER="paru"
        echo -e "${BLUE}Detected: Arch Linux (paru)${NC}"
    elif command -v yay &> /dev/null; then
        PKG_MANAGER="yay"
        echo -e "${BLUE}Detected: Arch Linux (yay)${NC}"
    else
        echo -e "${RED}Arch Linux detected but no AUR helper found${NC}"
        echo "Install paru or yay first"
        exit 1
    fi
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    echo -e "${BLUE}Detected: Fedora (dnf)${NC}"
else
    echo -e "${RED}No supported package manager found${NC}"
    exit 1
fi

echo ""

# Install backend (swaybg - simple and reliable)
echo -e "${GREEN}[1/2] Installing backend: swaybg${NC}"
if command -v swaybg &> /dev/null; then
    echo -e "${GREEN}✓ swaybg already installed${NC}"
else
    case $PKG_MANAGER in
        apt)
            sudo apt update
            sudo apt install -y swaybg
            ;;
        paru|yay)
            $PKG_MANAGER -S --needed --noconfirm swaybg
            ;;
        dnf)
            sudo dnf install -y swaybg
            ;;
    esac
    echo -e "${GREEN}✓ swaybg installed${NC}"
fi

echo ""

# Install waypaper (GUI) - optional
if [[ "$INSTALL_WAYPAPER" == true ]]; then
    echo -e "${GREEN}[2/2] Installing waypaper (GUI - optional)${NC}"
    if command -v waypaper &> /dev/null; then
        echo -e "${GREEN}✓ waypaper already installed${NC}"
    else
        # Install system dependencies for PyGObject (needed by waypaper)
        if [[ $PKG_MANAGER == "apt" ]]; then
            echo -e "${BLUE}Installing PyGObject dependencies...${NC}"
            sudo apt install -y libgirepository1.0-dev libgirepository-2.0-dev libcairo2-dev pkg-config python3-dev gir1.2-gtk-3.0
        fi

        # waypaper is best installed via pipx on most systems
        if command -v pipx &> /dev/null; then
            echo -e "${BLUE}Using pipx to install waypaper${NC}"
            pipx install waypaper
        elif [[ $PKG_MANAGER == "paru" ]] || [[ $PKG_MANAGER == "yay" ]]; then
            echo -e "${BLUE}Using $PKG_MANAGER to install waypaper${NC}"
            $PKG_MANAGER -S --needed --noconfirm waypaper
        else
            echo -e "${YELLOW}pipx not found, installing it first${NC}"
            case $PKG_MANAGER in
                apt)
                    sudo apt install -y pipx
                    pipx ensurepath
                    ;;
                dnf)
                    sudo dnf install -y pipx
                    pipx ensurepath
                    ;;
            esac
            pipx install waypaper
        fi
        echo -e "${GREEN}✓ waypaper installed${NC}"
    fi
else
    echo -e "${YELLOW}[2/2] Skipping waypaper (GUI) - terminal-only mode${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ "$INSTALL_WAYPAPER" == true ]]; then
    echo "You now have two ways to pick wallpapers:"
    echo ""
    echo -e "${BLUE}Option 1: GUI${NC}"
    echo "  Run: waypaper"
    echo ""
    echo -e "${BLUE}Option 2: Terminal (fzf with preview)${NC}"
    echo "  Run: ~/Bruno/code/wallpaperland/wallpaper-picker.sh"
    echo ""
    echo "Next steps:"
    echo "  1. Run 'waypaper' or the terminal script"
    echo "  2. Select wallpaper folder: ~/Pictures/wallpaper"
    echo "  3. Add keybinding to Hyprland (see QUICKSTART.md)"
else
    echo -e "${BLUE}Terminal wallpaper picker installed!${NC}"
    echo ""
    echo "Run: ~/Bruno/code/wallpaperland/wallpaper-picker.sh"
    echo ""
    echo "Next steps:"
    echo "  1. Run the script to select a wallpaper"
    echo "  2. Add keybinding: SUPER+W (see QUICKSTART.md)"
    echo ""
    echo -e "${YELLOW}Tip: Install waypaper for GUI option:${NC}"
    echo "  pipx install waypaper"
fi
