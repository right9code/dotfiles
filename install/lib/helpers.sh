#!/bin/bash

# Define ANSI escape codes for colored terminal output.
# These are used as a fallback when the 'gum' tool is not available.
# \033 is the escape character, [0;32m sets the color to green, etc.
_GREEN='\033[0;32m'
_BLUE='\033[0;34m'
_YELLOW='\033[1;33m'
_RED='\033[0;31m'
_CYAN='\033[0;36m'
_NC='\033[0m' # No Color (resets attributes to default)

# Define unicode icons to visually distinguish different types of log messages.
_ICON_STEP="▸"      # Used for main steps
_ICON_INFO="→"      # Used for informational messages
_ICON_SUCCESS="✓"   # Used for success messages
_ICON_ERROR="✗"     # Used for error messages
_ICON_ARROW="›"     # Used for detailed info (sub-items)

# Function to check if the 'gum' command-line tool is available in the system PATH.
# 'gum' is a tool for making glamorous shell scripts.
# Returns 0 (true) if found, non-zero (false) otherwise.
_has_gum() {
    command -v gum &> /dev/null
}

# Function to check if a specific package is installed on the system.
# Uses 'pacman -Q' to query the local package database.
# Arguments: $1 - The name of the package to check.
is_installed() {
    pacman -Q "$1" &>/dev/null
}

# Function to ensure that 'gum' is installed.
# If 'gum' is missing, it attempts to install it using pacman.
# This ensures that the script can use the enhanced UI features provided by gum.
ensure_gum() {
    if ! is_installed "gum"; then
        echo "Installing gum for better UI..."
        sudo pacman -S --noconfirm gum
    fi
}

# Function to print a stylized header for a section of the script.
# Arguments: $1 - The text to display in the header.
log_header() {
    local text="$1"

    if _has_gum; then
        echo
        # Use 'gum style' to create a bordered box with specific colors and padding.
        # --foreground 108: Sets text color (ANSI 108 is a light green).
        # --border double: Uses a double-line border style.
        gum style \
            --foreground 108 \
            --border double \
            --border-foreground 108 \
            --padding "0 2" \
            --margin "1 0" \
            --width 50 \
            --align center \
            "$text"
        echo
    else
        # Fallback: Print the text surrounded by ASCII lines using standard colors.
        echo -e "\n${_GREEN}════════════════════════════════════════${_NC}"
        echo -e "${_GREEN}  $text${_NC}"
        echo -e "${_GREEN}════════════════════════════════════════${_NC}\n"
    fi
}

# Function to log a major step in the installation process.
# Arguments: $1 - The step description.
log_step() {
    local text="$1"

    if _has_gum; then
        echo
        # Use 'gum style' to make the text bold and colored.
        gum style \
            --foreground 108 \
            --bold \
            "$_ICON_STEP $text"
    else
        # Fallback: Print with the step icon and green color.
        echo -e "\n${_GREEN}$_ICON_STEP${_NC} $text"
    fi
}

# Function to log general informational messages.
# Arguments: $1 - The message text.
log_info() {
    local text="$1"

    if _has_gum; then
        # Use a grey color (246) for info messages to keep them subtle.
        gum style \
            --foreground 246 \
            "  $_ICON_INFO $text"
    else
        # Fallback: Use yellow color.
        echo -e "  ${_YELLOW}$_ICON_INFO${_NC} $text"
    fi
}

# Function to log success messages.
# Arguments: $1 - The success message.
log_success() {
    local text="$1"

    if _has_gum; then
        # Use green color (108) for success.
        gum style \
            --foreground 108 \
            "  $_ICON_SUCCESS $text"
    else
        # Fallback: Use green color.
        echo -e "  ${_GREEN}$_ICON_SUCCESS${_NC} $text"
    fi
}

# Function to log error messages.
# Arguments: $1 - The error message.
log_error() {
    local text="$1"

    if _has_gum; then
        # Use red color (196) and bold text for errors to make them stand out.
        gum style \
            --foreground 196 \
            --bold \
            "  $_ICON_ERROR $text"
    else
        # Fallback: Use red color.
        echo -e "  ${_RED}$_ICON_ERROR${_NC} $text"
    fi
}

# Function to log detailed information, usually indented under a main log.
# Arguments: $1 - The detail text.
log_detail() {
    local text="$1"

    if _has_gum; then
        # Use a darker grey (241) for details.
        gum style \
            --foreground 241 \
            "    $_ICON_ARROW $text"
    else
        # Fallback: Use cyan color.
        echo -e "    ${_CYAN}$_ICON_ARROW${_NC} $text"
    fi
}

# Function to execute a command while displaying a loading spinner.
# Arguments: $1 - The title/description of the task.
#            $@ - The command to execute.
spinner() {
    local title="$1"
    shift # Remove the first argument (title), leaving the rest as the command.

    if _has_gum; then
        # Use 'gum spin' to show a spinner while the command runs.
        # --show-error: Displays the command's output if it fails.
        gum spin \
            --spinner dot \
            --title "$title" \
            --show-error \
            -- "$@"
    else
        # Fallback: Print a static loading icon and run the command directly.
        echo -e "${_CYAN}⟳${_NC} $title"
        "$@"
    fi
}

# Function to prompt the user for a Yes/No confirmation.
# Arguments: $1 - The question to ask.
# Returns: 0 for Yes, 1 for No.
ask_yes_no() {
    local prompt="$1"

    if _has_gum; then
        # Use 'gum confirm' for an interactive prompt.
        gum confirm "$prompt" && return 0 || return 1
    else
        # Fallback: Standard read loop until valid input is received.
        while true; do
            read -p "$prompt [y/n]: " yn
            case $yn in
                [Yy]* ) return 0;;
                [Nn]* ) return 1;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

# Function to log progress with a counter (e.g., [1/10]).
# Arguments: $1 - The text description.
#            $2 - The progress count string (e.g., "1/10").
log_progress() {
    local text="$1"
    local count="$2"

    if _has_gum; then
        gum style \
            --foreground 108 \
            "  [$count] $text"
    else
        echo -e "  ${_CYAN}[$count]${_NC} $text"
    fi
}

# Function to detect the hardware type (laptop vs desktop).
# This is useful for applying hardware-specific configurations (like power saving).
detect_hardware_type() {
    # Check for the existence of battery information in /sys/class/power_supply.
    # If a battery is found, we assume it's a laptop.
    if ls /sys/class/power_supply/BAT* >/dev/null 2>&1 || [ -d /sys/class/power_supply/battery ]; then
        echo "laptop"
    else
        echo "desktop"
    fi
}

# Function to check if an NVIDIA GPU is present in the system.
# Uses 'lspci' to list PCI devices and greps for "nvidia".
has_nvidia_gpu() {
    lspci | grep -i nvidia &>/dev/null
}

# Function to safely remove a file or directory.
# Arguments: $1 - The path to remove.
remove_path() {
    local target="$1"

    # Check if the target is a symbolic link (even a broken one).
    if [ -L "$target" ] && [ ! -e "$target" ]; then
        rm -f "$target"
    # Check if the target exists (file or directory).
    elif [ -e "$target" ]; then
        rm -rf "$target"
    fi
}
