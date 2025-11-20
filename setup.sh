#!/bin/bash

# 'set -e' ensures that the script exits immediately if any command returns a non-zero exit status (error).
# This is a safety feature to prevent the script from continuing execution in an unstable state.
set -e

# Define the absolute path where the dotfiles repository will be cloned.
# This follows the XDG Base Directory specification for user data.
DOTFILES_DIR="$HOME/.local/share/dotfiles"

# Define the remote URL of the git repository that contains the dotfiles.
# This is the source from which we will download the configuration files.
REPO_URL="https://github.com/right9code/dotfiles.git"

# Print a visual header to the terminal to indicate the start of the setup process.
echo "=============="
echo "Dotfiles Setup"
echo "=============="
echo

# Check if the target directory ($DOTFILES_DIR) already exists on the filesystem.
# The '-d' flag checks for the existence of a directory.
if [ -d "$DOTFILES_DIR" ]; then
    # If the directory exists, print an error message and instructions for the user.
    # We do not want to overwrite an existing installation without user intervention.
    echo "ERROR: $DOTFILES_DIR already exists!"
    echo "If you want to reinstall, please remove or backup the existing directory first:"
    echo "  mv ~/.local/share/dotfiles ~/.local/share/dotfiles.backup"
    
    # Exit the script with a status code of 1, indicating an error occurred.
    exit 1
fi

# Check if the 'git' command is available in the system's PATH.
# 'command -v' is a POSIX-compliant way to check for the existence of a command.
# '&> /dev/null' redirects both standard output and standard error to null, suppressing output.
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing git..."
    
    # If git is missing, attempt to install it using 'pacman', the package manager for Arch Linux.
    # 'sudo' is used to run the command with root privileges.
    # '--noconfirm' automatically answers "yes" to all prompts, allowing for unattended installation.
    sudo pacman -S --noconfirm git
    
    echo "Git installed successfully!"
fi

# Create the user's local configuration directory if it does not already exist.
# The '-p' flag ensures that no error is raised if the directory exists and creates parent directories as needed.
mkdir -p "$HOME/.config"

# Create the parent directory structure for the dotfiles location.
# This ensures that ~/.local/share exists before we try to clone into it.
mkdir -p "$HOME/.local/share/dotfiles"

# Clone the remote repository into the local target directory.
# This downloads all the files from GitHub to your computer.
echo "Cloning dotfiles repository..."
git clone "$REPO_URL" "$DOTFILES_DIR"

echo
echo "Repository cloned successfully!"
echo "Starting installation..."
echo

# Hand over control to the main installation script located inside the cloned repository.
# We use 'bash' explicitly to execute the script.
bash "$DOTFILES_DIR/install/install"
