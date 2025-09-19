#!/bin/bash

# A simple wrapper script to select a browser before opening a link.

# --- Function to get a list of installed browsers ---
# This function identifies available browsers by searching for .desktop files
# that handle web scheme MIME types.
get_browsers() {
  local browsers_found=()
  
  # Search in system, user, and Flatpak application directories
  local search_dirs=(
    "/usr/share/applications"
    "/usr/local/share/applications"
    "$HOME/.local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
  )
  
  for dir in "${search_dirs[@]}"; do
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
      done < <(find "$dir" -maxdepth 1 -name "*.desktop" -print0 2>/dev/null)
    fi
  done
  
  # Sort and remove duplicates based on name
  if [[ ${#browsers_found[@]} -gt 0 ]]; then
    printf '%s\n' "${browsers_found[@]}" | sort -u
  fi
}

# --- Function to extract and clean the Exec command ---
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

# --- Main script logic ---
main() {
  local url="$1"
  
  # If no URL is provided, exit with error
  if [[ -z "$url" ]]; then
    echo "Error: No URL provided." >&2
    echo "Usage: $0 <URL>" >&2
    exit 1
  fi
  
  echo "=========================================="
  echo "Browser Selector"
  echo "=========================================="
  echo "URL to open: $url"
  echo "Select a browser:"
  echo "------------------------------------------"
  
  # Get browsers and store in arrays
  local browser_names=()
  local browser_files=()
  local counter=1
  
  while IFS='|' read -r name file; do
    if [[ -n "$name" && -n "$file" ]]; then
      echo "$counter) $name"
      browser_names+=("$name")
      browser_files+=("$file")
      ((counter++))
    fi
  done < <(get_browsers)
  
  # Check if any browsers were found
  if [[ ${#browser_names[@]} -eq 0 ]]; then
    echo "Error: No web browsers found." >&2
    exit 1
  fi
  
  echo "------------------------------------------"
  
  # Get user selection
  local selection
  while true; do
    read -p "Enter your choice (1-${#browser_names[@]}): " selection
    
    # Validate input is a number
    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
      echo "Error: Please enter a valid number."
      continue
    fi
    
    # Validate selection is within range
    if [[ "$selection" -lt 1 || "$selection" -gt ${#browser_names[@]} ]]; then
      echo "Error: Please enter a number between 1 and ${#browser_names[@]}."
      continue
    fi
    
    break
  done
  
  # Get selected browser (adjust for 0-based array indexing)
  local selected_index=$((selection - 1))
  local selected_name="${browser_names[$selected_index]}"
  local selected_file="${browser_files[$selected_index]}"
  
  # Get the executable command
  local browser_command
  browser_command=$(get_exec_command "$selected_file")
  
  if [[ -z "$browser_command" ]]; then
    echo "Error: Could not determine how to launch $selected_name" >&2
    exit 1
  fi
  
  echo "------------------------------------------"
  echo "Opening '$url' with $selected_name..."
  echo "Command: $browser_command"
  echo "------------------------------------------"
  
  # Launch the browser with the URL
  # Use exec to replace the current process and avoid keeping this script running
  exec $browser_command "$url"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi