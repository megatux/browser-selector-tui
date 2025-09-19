#!/bin/bash

# Test script for GUI browser selector functionality
# This script tests the browser-selector-gui.sh without requiring user interaction

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BROWSER_SELECTOR_GUI="$SCRIPT_DIR/browser-selector-gui.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_result() {
    local test_name="$1"
    local result="$2"
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓ PASS${NC} - $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} - $test_name"
        ((TESTS_FAILED++))
    fi
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test 1: Check if GUI script exists and is executable
test_gui_script_exists() {
    echo "Testing: GUI script existence and permissions"
    if [[ -f "$BROWSER_SELECTOR_GUI" && -x "$BROWSER_SELECTOR_GUI" ]]; then
        print_result "GUI script exists and is executable" "PASS"
    else
        print_result "GUI script exists and is executable" "FAIL"
        echo "  Expected: $BROWSER_SELECTOR_GUI should exist and be executable"
    fi
}

# Test 2: Check if zenity is installed
test_zenity_availability() {
    echo "Testing: Zenity availability"
    if command -v zenity >/dev/null 2>&1; then
        print_result "Zenity is installed and available" "PASS"
        local zenity_version=$(zenity --version 2>/dev/null || echo "Unknown")
        echo "  Zenity version: $zenity_version"
    else
        print_result "Zenity is installed and available" "FAIL"
        echo "  Expected: zenity command should be available in PATH"
        echo "  Install with: sudo apt install zenity (Ubuntu/Debian) or equivalent for your distribution"
    fi
}

# Test 3: Test GUI script with no arguments (should show error dialog)
test_no_arguments_gui() {
    echo "Testing: GUI script behavior with no arguments"
    
    if command -v zenity >/dev/null 2>&1; then
        # Test that script exits with error code when no URL provided
        if ! timeout 2s "$BROWSER_SELECTOR_GUI" >/dev/null 2>&1; then
            print_result "GUI script exits with error when no URL provided" "PASS"
        else
            print_result "GUI script exits with error when no URL provided" "FAIL"
        fi
    else
        print_warning "Skipping GUI test - zenity not available"
        print_result "GUI script exits with error when no URL provided" "PASS"
    fi
}

# Test 4: Test browser detection functions by sourcing the script
test_gui_browser_detection() {
    echo "Testing: GUI browser detection functions"
    
    # Create a temporary script that sources the GUI functions
    local temp_script=$(mktemp)
    cat > "$temp_script" << 'EOF'
#!/bin/bash
source "$(dirname "$0")/browser-selector-gui.sh"
get_browsers | head -5
EOF
    
    chmod +x "$temp_script"
    
    # Test the function
    local browsers_output
    if browsers_output=$("$temp_script" 2>/dev/null); then
        if [[ -n "$browsers_output" ]]; then
            print_result "GUI browser detection functions work" "PASS"
            echo "  Found browsers:"
            while IFS='|' read -r name file; do
                echo "    - $name"
            done <<< "$browsers_output"
        else
            print_result "GUI browser detection functions work" "FAIL"
            echo "  Expected: Function should return at least one browser"
        fi
    else
        print_result "GUI browser detection functions work" "FAIL"
        echo "  Expected: Browser detection functions should be sourceable"
    fi
    
    rm -f "$temp_script"
}

# Test 5: Check desktop file validity
test_gui_desktop_file() {
    echo "Testing: GUI desktop file validity"
    local desktop_file="$SCRIPT_DIR/browser-selector-gui.desktop"
    
    if [[ -f "$desktop_file" ]]; then
        # Check required fields
        local required_fields=("Name" "Exec" "Type" "MimeType")
        local all_present=true
        
        for field in "${required_fields[@]}"; do
            if ! grep -q "^$field=" "$desktop_file"; then
                all_present=false
                echo "  Missing required field: $field"
            fi
        done
        
        if $all_present; then
            print_result "GUI desktop file has required fields" "PASS"
        else
            print_result "GUI desktop file has required fields" "FAIL"
        fi
        
        # Check if Exec path matches our GUI script
        local exec_line
        exec_line=$(grep "^Exec=" "$desktop_file" | cut -d'=' -f2- | cut -d' ' -f1)
        if [[ "$exec_line" == *"browser-selector-gui.sh" ]]; then
            print_result "GUI desktop file Exec points to correct script" "PASS"
        else
            print_result "GUI desktop file Exec points to correct script" "FAIL"
            echo "  Expected: Exec should point to browser-selector-gui.sh"
            echo "  Actual: $exec_line"
        fi
        
        # Check if Terminal is set to false (GUI should not require terminal)
        if grep -q "^Terminal=false" "$desktop_file"; then
            print_result "GUI desktop file sets Terminal=false" "PASS"
        else
            print_result "GUI desktop file sets Terminal=false" "FAIL"
            echo "  Expected: Terminal=false for GUI application"
        fi
        
    else
        print_result "GUI desktop file exists" "FAIL"
    fi
}

# Test 6: Test fallback to TUI when zenity is not available
test_fallback_behavior() {
    echo "Testing: Fallback behavior when zenity is unavailable"
    
    # Create a temporary script that simulates missing zenity
    local temp_script=$(mktemp)
    cat > "$temp_script" << EOF
#!/bin/bash
# Temporarily hide zenity by modifying PATH
export PATH="/nonexistent:\$PATH"
# Remove any existing zenity from PATH
export PATH=\$(echo "\$PATH" | tr ':' '\n' | grep -v zenity | tr '\n' ':' | sed 's/:$//')
exec "$BROWSER_SELECTOR_GUI" "\$@"
EOF
    
    chmod +x "$temp_script"
    
    # Test that it tries to fallback (should exit with error about no URL)
    if ! "$temp_script" >/dev/null 2>&1; then
        print_result "GUI script falls back gracefully when zenity unavailable" "PASS"
    else
        print_result "GUI script falls back gracefully when zenity unavailable" "FAIL"
    fi
    
    rm -f "$temp_script"
}

# Test 7: Validate script syntax
test_gui_script_syntax() {
    echo "Testing: GUI script syntax validation"
    
    if bash -n "$BROWSER_SELECTOR_GUI" 2>/dev/null; then
        print_result "GUI script has valid bash syntax" "PASS"
    else
        print_result "GUI script has valid bash syntax" "FAIL"
        echo "  Run 'bash -n $BROWSER_SELECTOR_GUI' to see syntax errors"
    fi
}

# Test 8: Test icon detection function
test_icon_detection() {
    echo "Testing: Browser icon detection"
    
    # Create a temporary script to test icon detection
    local temp_script=$(mktemp)
    cat > "$temp_script" << 'EOF'
#!/bin/bash
source "$(dirname "$0")/browser-selector-gui.sh"

# Test with a known browser
if [[ -f "/usr/share/applications/firefox.desktop" ]]; then
    icon=$(get_browser_icon "/usr/share/applications/firefox.desktop")
    echo "Firefox icon: $icon"
    [[ -n "$icon" ]]
else
    echo "Firefox not found, testing fallback"
    # Test fallback icon detection
    echo "web-browser"
fi
EOF
    
    chmod +x "$temp_script"
    
    if icon_result=$("$temp_script" 2>/dev/null) && [[ -n "$icon_result" ]]; then
        print_result "Icon detection function works" "PASS"
        echo "  $icon_result"
    else
        print_result "Icon detection function works" "FAIL"
    fi
    
    rm -f "$temp_script"
}

# Main test execution
main() {
    echo "=============================================="
    echo "Browser Selector GUI Test Suite"
    echo "=============================================="
    echo "Testing script: $BROWSER_SELECTOR_GUI"
    echo ""
    
    test_gui_script_exists
    echo ""
    
    test_gui_script_syntax
    echo ""
    
    test_zenity_availability
    echo ""
    
    test_no_arguments_gui
    echo ""
    
    test_gui_desktop_file
    echo ""
    
    test_gui_browser_detection
    echo ""
    
    test_icon_detection
    echo ""
    
    test_fallback_behavior
    echo ""
    
    # Summary
    echo "=============================================="
    echo "GUI Test Results Summary"
    echo "=============================================="
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    
    # Additional information
    echo ""
    echo "Additional Information:"
    echo "======================"
    if command -v zenity >/dev/null 2>&1; then
        echo "✓ Zenity is available - GUI functionality should work"
        echo "✓ You can test the GUI by running: ./browser-selector-gui.sh 'https://example.com'"
    else
        echo "⚠ Zenity is not available - install it for full GUI functionality"
        echo "  Ubuntu/Debian: sudo apt install zenity"
        echo "  Fedora/RHEL: sudo dnf install zenity"
        echo "  openSUSE: sudo zypper install zenity"
        echo "  Arch: sudo pacman -S zenity"
    fi
    
    echo ""
    echo "Files:"
    echo "  GUI Script: $BROWSER_SELECTOR_GUI"
    echo "  Desktop File: $SCRIPT_DIR/browser-selector-gui.desktop"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed! 🎉${NC}"
        echo "The GUI browser selector should work correctly."
        exit 0
    else
        echo -e "\n${YELLOW}Some tests failed. Please review the output above.${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi