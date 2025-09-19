#!/bin/bash

# Browser Selector Installation Script
# This script installs the browser selector to your system

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
    
    print_success "All requirements met"
}

create_directories() {
    print_status "Creating directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DESKTOP_DIR"
    
    print_success "Directories created"
}

install_script() {
    print_status "Installing browser selector script..."
    
    local source_script="$SCRIPT_DIR/browser-selector.sh"
    local target_script="$INSTALL_DIR/browser-selector.sh"
    
    if [[ ! -f "$source_script" ]]; then
        print_error "Source script not found: $source_script"
        exit 1
    fi
    
    cp "$source_script" "$target_script"
    chmod +x "$target_script"
    
    print_success "Script installed to $target_script"
}

install_desktop_file() {
    print_status "Installing desktop file..."
    
    local source_desktop="$SCRIPT_DIR/browser-selector.desktop"
    local target_desktop="$DESKTOP_DIR/browser-selector.desktop"
    
    if [[ ! -f "$source_desktop" ]]; then
        print_error "Source desktop file not found: $source_desktop"
        exit 1
    fi
    
    # Create a custom desktop file with the correct path
    cat > "$target_desktop" << EOF
[Desktop Entry]
Version=1.0
Name=Browser Selector
GenericName=Web Browser Selector
Comment=Select which browser to use when opening URLs
Exec=$INSTALL_DIR/browser-selector.sh %U
Icon=web-browser
Terminal=true
Type=Application
Categories=Network;WebBrowser;System;
MimeType=x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;text/html;application/xhtml+xml;
StartupNotify=false
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
    print_status "Would you like to set Browser Selector as your default web browser?"
    echo "This will make it handle all web links system-wide."
    echo ""
    read -p "Set as default browser? [y/N]: " -r
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v xdg-settings >/dev/null 2>&1; then
            if xdg-settings set default-web-browser browser-selector.desktop 2>/dev/null; then
                print_success "Browser Selector set as default web browser"
            else
                print_error "Failed to set as default browser"
                echo "You can set it manually later with:"
                echo "xdg-settings set default-web-browser browser-selector.desktop"
            fi
        else
            print_warning "xdg-settings not found. Cannot set as default browser automatically."
            echo "You may need to set it through your desktop environment's settings."
        fi
    else
        print_status "Browser Selector installed but not set as default"
        echo "You can set it as default later with:"
        echo "xdg-settings set default-web-browser browser-selector.desktop"
    fi
}

run_tests() {
    echo ""
    print_status "Would you like to run tests to verify the installation?"
    read -p "Run tests? [y/N]: " -r
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local test_script="$SCRIPT_DIR/test-func.sh"
        if [[ -f "$test_script" && -x "$test_script" ]]; then
            echo ""
            print_status "Running installation verification tests..."
            if "$test_script"; then
                print_success "All tests passed!"
            else
                print_warning "Some tests failed, but installation may still work"
            fi
        else
            print_warning "Test script not found or not executable"
        fi
    fi
}

show_usage_info() {
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    echo "Usage:"
    echo "  Command line: browser-selector.sh 'https://example.com'"
    echo "  Desktop: Click any web link to see browser selection menu"
    echo ""
    echo "Files installed:"
    echo "  Script: $INSTALL_DIR/browser-selector.sh"
    echo "  Desktop: $DESKTOP_DIR/browser-selector.desktop"
    echo ""
    echo "To uninstall, simply delete these files."
    echo ""
}

main() {
    echo "=========================================="
    echo "Browser Selector Installation"
    echo "=========================================="
    echo ""
    
    check_requirements
    echo ""
    
    create_directories
    echo ""
    
    install_script
    echo ""
    
    install_desktop_file
    echo ""
    
    update_desktop_database
    echo ""
    
    check_path
    echo ""
    
    offer_default_browser_setup
    
    run_tests
    
    show_usage_info
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi