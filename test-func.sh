#!/bin/bash

# Isolated test for the get_browsers function

# Copy of the get_browsers function
get_browsers() {
  local browsers_found=()
  
  # Search in both system and user application directories
  for dir in "/usr/share/applications" "$HOME/.local/share/applications"; do
    if [[ -d "$dir" ]]; then
      while IFS= read -r -d '' desktop_file; do
        # Skip our own desktop file to avoid infinite loops
        if [[ "$(basename "$desktop_file")" == "browser-selector.desktop" ]]; then
          continue
        fi
        
        # Check if this desktop file handles HTTP URLs
        if grep -q "x-scheme-handler/http" "$desktop_file" 2>/dev/null; then
          local name
          name=$(grep -m1 "^Name=" "$desktop_file" 2>/dev/null | cut -d'=' -f2-)
          if [[ -n "$name" ]]; then
            browsers_found+=("$name|$desktop_file")
          fi
        fi
      done < <(find "$dir" -maxdepth 1 -name "*.desktop" -type f -print0 2>/dev/null)
    fi
  done
  
  # Sort and remove duplicates based on name
  if [[ ${#browsers_found[@]} -gt 0 ]]; then
    printf '%s\n' "${browsers_found[@]}" | sort -u
  fi
}

# Copy of the get_exec_command function
get_exec_command() {
  local desktop_file="$1"
  local exec_line
  
  if [[ ! -f "$desktop_file" ]]; then
    return 1
  fi
  
  # Get the Exec line from the desktop file
  exec_line=$(grep -m1 "^Exec=" "$desktop_file" 2>/dev/null | cut -d'=' -f2-)
  
  if [[ -z "$exec_line" ]]; then
    return 1
  fi
  
  # Remove common desktop file placeholders and clean up whitespace
  exec_line=$(echo "$exec_line" | sed -e 's/%[uUfFdDnNickvm]//g' -e 's/[[:space:]]\+/ /g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  
  echo "$exec_line"
}

echo "Testing get_browsers function:"
echo "=============================="

browsers_output=$(get_browsers)

if [[ -n "$browsers_output" ]]; then
    echo "✓ Found browsers:"
    counter=1
    while IFS='|' read -r name file; do
        if [[ -n "$name" && -n "$file" ]]; then
            echo "  $counter) $name"
            echo "     File: $(basename "$file")"
            echo "     Full path: '$file'"
            
            # Test get_exec_command for this browser
            exec_cmd=$(get_exec_command "$file")
            if [[ -n "$exec_cmd" ]]; then
                echo "     Command: '$exec_cmd'"
            else
                echo "     Command: [ERROR - Could not extract command]"
            fi
            echo ""
            ((counter++))
        fi
    done <<< "$browsers_output"
    
    echo "Total browsers found: $((counter - 1))"
else
    echo "✗ No browsers found!"
    exit 1
fi

echo ""
echo "Function test completed!"