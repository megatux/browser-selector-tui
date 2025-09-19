#!/bin/bash

# Test script for browser selector functionality
# This script tests the browser-selector.sh without actually opening browsers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BROWSER_SELECTOR="$SCRIPT_DIR/browser-selector.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Test 1: Check if script exists and is executable
test_script_exists() {
    echo "Testing: Script existence and permissions"
    if [[ -f "$BROWSER_SELECTOR" && -x "$BROWSER_SELECTOR" ]]; then
        print_result "Script exists and is executable" "PASS"
    else
        print_result "Script exists and is executable" "FAIL"
        echo "  Expected: $BROWSER_SELECTOR should exist and be executable"
    fi
}

# Test 2: Test script with no arguments
test_no_arguments() {
    echo "Testing: Script behavior with no arguments"
    if ! "$BROWSER_SELECTOR" 2>/dev/null; then
        print_result "Script exits with error when no URL provided" "PASS"
    else
        print_result "Script exits with error when no URL provided" "FAIL"
    fi
}

# Test 3: Test get_browsers function by sourcing the script
test_get_browsers_function() {
    echo "Testing: get_browsers function"
    
    # Source the script to access the function
    if source "$BROWSER_SELECTOR" 2>/dev/null; then
        local browsers_output
        browsers_output=$(get_browsers 2>/dev/null)
            
        if [[ -n "$browsers_output" ]]; then
            print_result "get_browsers function returns browser list" "PASS"
            echo "  Found browsers:"
            while IFS='|' read -r name file; do
                echo "    - $name ($file)"
            done <<< "$browsers_output"
        else
            print_result "get_browsers function returns browser list" "FAIL"
            echo "  Expected: Function should return at least one browser"
        fi
    else
        print_result "get_browsers function can be sourced" "FAIL"
    fi
}

# Test 4: Check desktop file syntax
test_desktop_file() {
    echo "Testing: Desktop file validity"
    local desktop_file="$SCRIPT_DIR/browser-selector.desktop"
    
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
            print_result "Desktop file has required fields" "PASS"
        else
            print_result "Desktop file has required fields" "FAIL"
        fi
        
        # Check if Exec path matches our script
        local exec_line
        exec_line=$(grep "^Exec=" "$desktop_file" | cut -d'=' -f2- | cut -d' ' -f1)
        if [[ "$exec_line" == *"browser-selector.sh" ]]; then
            print_result "Desktop file Exec points to correct script" "PASS"
        else
            print_result "Desktop file Exec points to correct script" "FAIL"
            echo "  Expected: Exec should point to browser-selector.sh"
            echo "  Actual: $exec_line"
        fi
    else
        print_result "Desktop file exists" "FAIL"
    fi
}

# Test 5: Test individual functions by creating a mock environment
test_get_exec_command() {
    echo "Testing: get_exec_command function"
    
    # Create a temporary desktop file for testing
    local temp_desktop
    temp_desktop=$(mktemp)
    cat > "$temp_desktop" << 'EOF'
[Desktop Entry]
Name=Test Browser
Exec=test-browser %U --new-window
Type=Application
MimeType=x-scheme-handler/http;x-scheme-handler/https;
EOF
    
    # Source the script and test the function
    if source "$BROWSER_SELECTOR" 2>/dev/null; then
        local result
        result=$(get_exec_command "$temp_desktop")
        
        if [[ "$result" == "test-browser --new-window" ]]; then
            print_result "get_exec_command removes placeholders correctly" "PASS"
        else
            print_result "get_exec_command removes placeholders correctly" "FAIL"
            echo "  Expected: 'test-browser --new-window'"
            echo "  Actual: '$result'"
        fi
    else
        print_result "get_exec_command function can be tested" "FAIL"
    fi
    
    rm -f "$temp_desktop"
}

# Test 6: Check for common browser desktop files
test_browser_detection() {
    echo "Testing: Browser detection in system"
    
    local common_browsers=("firefox" "google-chrome" "chromium" "brave" "opera")
    local browsers_found=0
    
    for browser in "${common_browsers[@]}"; do
        if find /usr/share/applications ~/.local/share/applications -name "*${browser}*.desktop" -type f 2>/dev/null | head -1 | read; then
            ((browsers_found++))
            echo "  Found: $browser"
        fi
    done
    
    if [[ $browsers_found -gt 0 ]]; then
        print_result "System has detectable browsers" "PASS"
        echo "  Detected $browsers_found common browser(s)"
    else
        print_result "System has detectable browsers" "FAIL"
        echo "  No common browsers found - this might affect functionality"
    fi
}

# Test 7: Validate script syntax
test_script_syntax() {
    echo "Testing: Script syntax validation"
    
    if bash -n "$BROWSER_SELECTOR" 2>/dev/null; then
        print_result "Script has valid bash syntax" "PASS"
    else
        print_result "Script has valid bash syntax" "FAIL"
        echo "  Run 'bash -n $BROWSER_SELECTOR' to see syntax errors"
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "Browser Selector Test Suite"
    echo "=========================================="
    echo "Testing script: $BROWSER_SELECTOR"
    echo ""
    
    test_script_exists
    echo ""
    
    test_script_syntax
    echo ""
    
    test_no_arguments
    echo ""
    
    test_desktop_file
    echo ""
    
    test_get_browsers_function
    echo ""
    
    test_get_exec_command
    echo ""
    
    test_browser_detection
    echo ""
    
    # Summary
    echo "=========================================="
    echo "Test Results Summary"
    echo "=========================================="
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed! 🎉${NC}"
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