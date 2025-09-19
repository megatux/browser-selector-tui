# Browser Selector

A bash script that allows you to choose which web browser to use when opening URLs, instead of being limited to your system's default browser.

## Features

- **Interactive browser selection**: Choose from all installed web browsers when opening a URL
- **Automatic browser detection**: Finds all browsers installed on your system that can handle HTTP/HTTPS URLs
- **Multi-platform support**: Detects browsers installed via:
  - System packages (`/usr/share/applications`)
  - User installations (`~/.local/share/applications`)
  - Flatpak applications (`/var/lib/flatpak/exports/share/applications`)
  - Local installations (`/usr/local/share/applications`)
- **Clean command extraction**: Properly extracts executable commands from desktop files, including Flatpak commands
- **Self-exclusion**: Prevents infinite loops by excluding itself from the browser list
- **Error handling**: Provides clear error messages and validates user input
- **Symbolic link support**: Handles Flatpak symbolic links correctly

## Installation

### Quick Setup

1. Copy the script to your local bin directory:
```bash
cp browser-selector.sh ~/.local/bin/
chmod +x ~/.local/bin/browser-selector.sh
```

2. Copy the desktop file to your local applications directory:
```bash
cp browser-selector.desktop ~/.local/share/applications/
```

3. Update the desktop database:
```bash
update-desktop-database ~/.local/share/applications/
```

4. Set as your default browser:
```bash
xdg-settings set default-web-browser browser-selector.desktop
```

### Automated Installation

Use the included installation script:
```bash
./install.sh
```

This will guide you through the installation process and optionally set the browser selector as your default browser.

## Usage

### Command Line
```bash
# Open a URL with browser selection
./browser-selector.sh "https://example.com"

# The script will show you available browsers and let you choose
```

### As Default Browser
Once installed and set as your default browser, clicking any web link will:
1. Show you a list of available browsers
2. Let you choose which one to use
3. Open the URL with your selected browser

### Example Output
```
==========================================
Browser Selector
==========================================
URL to open: https://example.com
Select a browser:
------------------------------------------
1) Brave
2) Firefox
3) Microsoft Edge
4) Ungoogled Chromium
5) Vivaldi
6) Web (Epiphany)
7) Zen Browser
------------------------------------------
Enter your choice (1-7): 3
------------------------------------------
Opening 'https://example.com' with Microsoft Edge...
Command: /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/edge --file-forwarding com.microsoft.Edge @@u @@
------------------------------------------
```

## How It Works

1. **Browser Detection**: The script searches for `.desktop` files in multiple directories that handle HTTP/HTTPS URLs
2. **Command Extraction**: It extracts the executable command from each desktop file, removing placeholder arguments like `%u`
3. **Flatpak Support**: Handles Flatpak applications by following symbolic links and extracting proper Flatpak run commands
4. **User Selection**: Presents a numbered list of browsers for user selection
5. **URL Opening**: Launches the selected browser with the provided URL

## Supported Installation Methods

### Native Package Browsers
- Firefox
- Google Chrome / Chromium
- Vivaldi
- Opera
- Epiphany (GNOME Web)
- And many others installed via system package managers

### Flatpak Browsers
- Microsoft Edge
- Zen Browser
- Brave Browser
- Ungoogled Chromium
- Any other Flatpak browser that declares HTTP scheme handling

### Detection Locations
The script searches these directories for browser desktop files:
- `/usr/share/applications/` - System-wide applications
- `/usr/local/share/applications/` - Local system applications  
- `~/.local/share/applications/` - User applications
- `/var/lib/flatpak/exports/share/applications/` - System Flatpak applications
- `~/.local/share/flatpak/exports/share/applications/` - User Flatpak applications

## Requirements

- Bash 4.0 or later
- Standard Linux desktop environment with `.desktop` files
- `grep`, `find`, `cut`, `sed` (standard on most Linux systems)

## Troubleshooting

### Browser not detected
If your browser isn't showing up:

1. **Check desktop file locations**: Run `find /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications -name "*browser_name*" 2>/dev/null`

2. **Verify MIME type declarations**: Check if the browser's `.desktop` file includes `x-scheme-handler/http` in its `MimeType` field:
   ```bash
   grep "MimeType" /path/to/browser.desktop
   ```

3. **Test browser detection**: Use the test script to debug:
   ```bash
   ./test-func.sh
   ```

### Flatpak browsers not detected
- Ensure Flatpak browsers are properly installed and have desktop files in `/var/lib/flatpak/exports/share/applications/`
- Check that the symbolic links are valid and point to actual desktop files
- Verify the Flatpak browser declares HTTP scheme handling in its MIME types

### Permission errors
- Make sure the script is executable: `chmod +x browser-selector.sh`
- Ensure the script path in the desktop file is correct
- Check that you have read access to all application directories

### Browser won't launch
- Verify the extracted command is valid by running it manually
- For Flatpak browsers, ensure the Flatpak runtime is properly installed
- Some browsers may require additional setup or have complex launch requirements

## Testing

Run the included test suite:
```bash
./test-browser-selector.sh
```

Or test browser detection specifically:
```bash
./test-func.sh
```

## Configuration

### Desktop File Customization
You can modify `browser-selector.desktop` to:
- Change the name or description
- Add or remove MIME types
- Customize the icon
- Set terminal preferences

### Script Customization
The script can be modified to:
- Change the output format
- Add browser filtering
- Implement browser preferences/favorites
- Add keyboard shortcuts for common browsers

## Files

- `browser-selector.sh` - Main script with Flatpak support
- `browser-selector.desktop` - Desktop entry file
- `install.sh` - Automated installation script
- `test-browser-selector.sh` - Comprehensive test suite
- `test-func.sh` - Function-specific tests
- `README.md` - This documentation

## Recent Improvements

### Version 2.0 Changes
- **Flatpak Support**: Added detection for Flatpak browsers including Edge and Zen Browser
- **Symbolic Link Handling**: Properly handles symbolic links used by Flatpak applications
- **Expanded Search Locations**: Now searches 5 different application directories
- **Improved Command Extraction**: Better handling of complex Flatpak run commands
- **Enhanced Testing**: More comprehensive test suite for debugging detection issues

## Contributing

1. Test your changes with the provided test scripts
2. Ensure compatibility with both native and Flatpak browsers
3. Follow bash best practices
4. Update documentation as needed

## License

This project is in the public domain. Use it however you like!

## Background

This script was created to solve the common problem where users want to choose which browser to use when clicking links, rather than being stuck with their system's default browser. It's particularly useful for:

- Web developers who need to test in multiple browsers
- Users who prefer different browsers for different tasks (e.g., Edge for work, Firefox for personal)
- Anyone who wants more control over their browsing experience
- Users with multiple browsers installed via different methods (system packages, Flatpak, etc.)

The script has evolved to support modern Linux application distribution methods like Flatpak, making it work seamlessly with browsers like Microsoft Edge and Zen Browser that are commonly distributed as Flatpak applications.