#!/bin/bash

# Browser Selector GUI Installation Script
# This script installs the GUI browser selector to your system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    print_status "Checking requirements..."
    
    # Check if bash version is 4.0 or later
    if ((BASH_VERSINFO[0] < 4)); then
        print_error "Bash 4.0 or later is required. Current version: $BASH_VERSION"
        exit 1
    fi
    
    # Check for required commands
    local required_commands=("grep" "find" "cut" "sed" "sort")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_error "Required command not found: $cmd"
            exit 1
        fi
    done
    
    # Check for zenity (critical for GUI)
    if ! command -v zenity >/dev/null 2>&1; then
        print_error "zenity is required for GUI functionality but is not installed."
        echo ""
        echo "Please install zenity using your package manager:"
        echo "  Ubuntu/Debian: sudo apt install zenity"
        echo "  Fedora/RHEL:   sudo dnf install zenity"
        echo "  openSUSE:      sudo zypper install zenity"
        echo "  Arch Linux:    sudo pacman -S zenity"
        echo ""
        read -p "Would you like to install the TUI version instead? [y/N]: " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installing TUI version..."
            exec "$SCRIPT_DIR/install.sh"
        else
            exit 1
        fi
    fi
    
    print_success "All requirements met"
}

create_directories() {
    print_status "Creating directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DESKTOP_DIR"
    
    print_success "Directories created"
}

install_gui_script() {
    print_status "Installing GUI browser selector script..."
    
    local source_script="$SCRIPT_DIR/browser-selector-gui.sh"
    local target_script="$INSTALL_DIR/browser-selector-gui.sh"
    
    if [[ ! -f "$source_script" ]]; then
        print_error "Source GUI script not found: $source_script"
        exit 1
    fi
    
    cp "$source_script" "$target_script"
    chmod +x "$target_script"
    
    print_success "GUI script installed to $target_script"
}

install_tui_script_fallback() {
    print_status "Installing TUI fallback script..."
    
    local source_script="$SCRIPT_DIR/browser-selector.sh"
    local target_script="$INSTALL_DIR/browser-selector.sh"
    
    if [[ -f "$source_script" ]]; then
        cp "$source_script" "$target_script"
        chmod +x "$target_script"
        print_success "TUI fallback script installed to $target_script"
    else
        print_warning "TUI fallback script not found - GUI will have no fallback"
    fi
}

install_desktop_file() {
    print_status "Installing desktop file..."
    
    local source_desktop="$SCRIPT_DIR/browser-selector-gui.desktop"
    local target_desktop="$DESKTOP_DIR/browser-selector-gui.desktop"
    
    if [[ ! -f "$source_desktop" ]]; then
        print_warning "Source desktop file not found, creating one..."
    fi
    
    # Create a custom desktop file with the correct path
    cat > "$target_desktop" << EOF
[Desktop Entry]
Version=1.0
Name=Browser Selector (GUI)
GenericName=Web Browser Selector
Comment=Select which browser to use when opening URLs (GUI version)
Exec=$INSTALL_DIR/browser-selector-gui.sh %U
Icon=web-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;System;
MimeType=x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;text/html;application/xhtml+xml;
StartupNotify=true
NoDisplay=false
EOF
    
    print_success "Desktop file installed to $target_desktop"
}

update_desktop_database() {
    print_status "Updating desktop database..."
    
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$DESKTOP_DIR" 2>/dev/null || print_warning "Failed to update desktop database (non-critical)"
        print_success "Desktop database updated"
    else
        print_warning "update-desktop-database not found, skipping (non-critical)"
    fi
}

check_path() {
    print_status "Checking PATH configuration..."
    
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        print_success "Install directory is in PATH"
    else
        print_warning "Install directory ($INSTALL_DIR) is not in PATH"
        echo "To use the script from command line, add this to your shell profile:"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\""
    fi
}

offer_default_browser_setup() {
    echo ""
    print_status "Would you like to set Browser Selector (GUI) as your default web browser?"
    echo "This will make it handle all web links system-wide with a GUI dialog."
    echo ""
    read -p "Set as default browser? [y/N]: " -r
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v xdg-settings >/dev/null 2>&1; then
            if xdg-settings set default-web-browser browser-selector-gui.desktop 2>/dev/null; then
                print_success "Browser Selector (GUI) set as default web browser"
            else
                print_error "Failed to set as default browser"
                echo "You can set it manually later with:"
                echo "xdg-settings set default-web-browser browser-selector-gui.desktop"
            fi
        else
            print_warning "xdg-settings not found. Cannot set as default browser automatically."
            echo "You may need to set it through your desktop environment's settings."
        fi
    else
        print_status "Browser Selector (GUI) installed but not set as default"
        echo "You can set it as default later with:"
        echo "xdg-settings set default-web-browser browser-selector-gui.desktop"
    fi
}

test_gui_functionality() {
    echo ""
    print_status "Would you like to test the GUI functionality?"
    read -p "Test GUI browser selector? [y/N]: " -r
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local test_script="$SCRIPT_DIR/test-gui.sh"
        if [[ -f "$test_script" && -x "$test_script" ]]; then
            echo ""
            print_status "Running GUI functionality tests..."
            if "$test_script"; then
                print_success "All GUI tests passed!"
                echo ""
                print_status "Testing with actual GUI dialog..."
                echo "A browser selection dialog should appear shortly..."
                sleep 2
                timeout 10s "$INSTALL_DIR/browser-selector-gui.sh" "https://example.com" >/dev/null 2>&1 || true
            else
                print_warning "Some tests failed, but installation may still work"
            fi
        else
            print_warning "Test script not found or not executable"
            print_status "Testing basic functionality..."
            echo "A browser selection dialog should appear shortly..."
            sleep 2
            timeout 10s "$INSTALL_DIR/browser-selector-gui.sh" "https://example.com" >/dev/null 2>&1 || true
        fi
    fi
}

show_usage_info() {
    echo ""
    print_success "GUI Installation completed successfully!"
    echo ""
    echo "Usage:"
    echo "  Command line: browser-selector-gui.sh 'https://example.com'"
    echo "  Desktop: Click any web link to see GUI browser selection dialog"
    echo ""
    echo "Features:"
    echo "  ✓ GUI dialog with radio button selection"
    echo "  ✓ Browser icons displayed in selection list"
    echo "  ✓ Notification when launching browser"
    echo "  ✓ Automatic fallback to terminal if zenity unavailable"
    echo "  ✓ Support for all browser types (native, Flatpak, etc.)"
    echo ""
    echo "Files installed:"
    echo "  GUI Script: $INSTALL_DIR/browser-selector-gui.sh"
    echo "  TUI Fallback: $INSTALL_DIR/browser-selector.sh (if available)"
    echo "  Desktop: $DESKTOP_DIR/browser-selector-gui.desktop"
    echo ""
    echo "To uninstall, simply delete these files."
    echo ""
}

main() {
    echo "=================================================="
    echo "Browser Selector GUI Installation"
    echo "=================================================="
    echo "This will install the GUI version of Browser Selector"
    echo "which uses zenity for graphical browser selection."
    echo ""
    
    check_requirements
    echo ""
    
    create_directories
    echo ""
    
    install_gui_script
    echo ""
    
    install_tui_script_fallback
    echo ""
    
    install_desktop_file
    echo ""
    
    update_desktop_database
    echo ""
    
    check_path
    echo ""
    
    offer_default_browser_setup
    
    test_gui_functionality
    
    show_usage_info
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi