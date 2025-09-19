#!/bin/bash

# A GUI wrapper script to select a browser before opening a link using zenity.

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
        if [[ "$(basename "$desktop_file")" == "browser-selector-gui.desktop" ]] || 
           [[ "$(basename "$desktop_file")" == "browser-selector.desktop" ]]; then
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

# --- Function to get browser icon from desktop file ---
get_browser_icon() {
  local desktop_file="$1"
  local icon
  
  icon=$(grep -m1 "^Icon=" "$desktop_file" 2>/dev/null | cut -d'=' -f2-)
  
  # If no icon found or icon doesn't exist, try to determine from browser name/file
  if [[ -z "$icon" ]] || ! gtk-update-icon-cache --help >/dev/null 2>&1; then
    local browser_name=$(basename "$desktop_file" .desktop)
    case "$browser_name" in
      *firefox*) icon="firefox" ;;
      *chrome*|*chromium*) icon="google-chrome" ;;
      *edge*) icon="microsoft-edge" ;;
      *brave*) icon="brave-browser" ;;
      *vivaldi*) icon="vivaldi" ;;
      *opera*) icon="opera" ;;
      *epiphany*) icon="org.gnome.Epiphany" ;;
      *zen*) icon="zen-browser" ;;
      *) icon="web-browser" ;;
    esac
  fi
  
  echo "$icon"
}

# --- Function to check if zenity is available ---
check_zenity() {
  if ! command -v zenity >/dev/null 2>&1; then
    # Fallback to terminal if zenity is not available
    echo "Error: zenity is not installed. Please install zenity for GUI mode." >&2
    echo "Falling back to terminal mode..." >&2
    return 1
  fi
  return 0
}

# --- Main script logic ---
main() {
  local url="$1"
  
  # If no URL is provided, show error dialog
  if [[ -z "$url" ]]; then
    if check_zenity; then
      zenity --error \
             --title="Browser Selector" \
             --text="No URL provided.\n\nUsage: $0 <URL>" \
             --width=350
    else
      echo "Error: No URL provided." >&2
      echo "Usage: $0 <URL>" >&2
    fi
    exit 1
  fi
  
  # Check if zenity is available
  if ! check_zenity; then
    # Fallback to original TUI behavior
    echo "Zenity not available, using terminal interface..."
    exec "$(dirname "$0")/browser-selector.sh" "$url"
  fi
  
  # Get browsers and build zenity list format
  local browser_data=()
  local browser_names=()
  local browser_files=()
  local browser_icons=()
  
  while IFS='|' read -r name file; do
    if [[ -n "$name" && -n "$file" ]]; then
      local icon=$(get_browser_icon "$file")
      browser_data+=("FALSE" "$name" "$icon")
      browser_names+=("$name")
      browser_files+=("$file")
      browser_icons+=("$icon")
    fi
  done < <(get_browsers)
  
  # Check if any browsers were found
  if [[ ${#browser_names[@]} -eq 0 ]]; then
    zenity --error \
           --title="Browser Selector" \
           --text="No web browsers found on this system.\n\nPlease install a web browser that supports HTTP URLs." \
           --width=400
    exit 1
  fi
  
  # Set the first browser as selected by default
  if [[ ${#browser_data[@]} -gt 0 ]]; then
    browser_data[0]="TRUE"
  fi
  
  # Truncate long URLs for display
  local display_url="$url"
  if [[ ${#url} -gt 60 ]]; then
    display_url="${url:0:40}...${url: -15}"
  fi
  
  # Show browser selection dialog with improved layout
  local selected_browser
  selected_browser=$(zenity --list \
                            --radiolist \
                            --title="Browser Selector" \
                            --text="Select a browser to open:\n\n<b>$display_url</b>\n\nAvailable browsers:" \
                            --column="Select" \
                            --column="Browser Name" \
                            --column="Icon" \
                            --width=550 \
                            --height=450 \
                            --hide-column=3 \
                            --ok-label="Open Browser" \
                            --cancel-label="Cancel" \
                            "${browser_data[@]}" 2>/dev/null)
  
  # Check if user cancelled or no selection was made
  if [[ -z "$selected_browser" ]]; then
    # User cancelled - exit silently
    exit 0
  fi
  
  # Find the selected browser's file path
  local selected_file=""
  local browser_command=""
  
  for i in "${!browser_names[@]}"; do
    if [[ "${browser_names[i]}" == "$selected_browser" ]]; then
      selected_file="${browser_files[i]}"
      break
    fi
  done
  
  # Get the executable command
  browser_command=$(get_exec_command "$selected_file")
  
  if [[ -z "$browser_command" ]]; then
    zenity --error \
           --title="Browser Selector" \
           --text="Error: Could not determine how to launch $selected_browser\n\nDesktop file: $selected_file" \
           --width=450
    exit 1
  fi
  
  # Show a brief notification instead of progress dialog for better UX
  zenity --notification \
         --text="Opening $url with $selected_browser" \
         --timeout=3 2>/dev/null &
  
  # Launch the browser with the URL
  # Use exec to replace the current process and avoid keeping this script running
  exec $browser_command "$url"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi