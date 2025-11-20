#!/bin/bash

# Define the root directory where all backups will be stored.
# This keeps backups organized in one place rather than scattering them.
BACKUP_ROOT="$HOME/dotfiles-backup"

# Define the path to a session file that stores the current backup session's details.
# This file acts as a shared state between different scripts running in the same installation session.
SESSION_FILE="$HOME/.local/share/dotfiles/.dotfiles-backup-session"

# Function to initialize a new backup session.
# This is called once at the beginning of the installation process.
# It creates a unique directory for the current run and prepares the restore instructions.
init_backup_session() {
  # Generate a unique session ID based on the current date and time (YYYYMMDD_HHMMSS).
  local BACKUP_SESSION="backup_$(date +%Y%m%d_%H%M%S)"
  
  # Define the full path for the current session's backup directory.
  local BACKUP_DIR="$BACKUP_ROOT/$BACKUP_SESSION"
  
  # Define the path for the restore instructions file.
  # This file will contain commands to undo changes made during this session.
  local RESTORE_FILE="$BACKUP_DIR/RESTORE.txt"

  # Create the backup directory, including any necessary parent directories.
  mkdir -p "$BACKUP_DIR"

  # Save the session details (ID, directory path, restore file path) to the session file.
  # This allows other scripts (like setup-zsh, setup-config) to know where to save their backups
  # without needing to pass these variables around manually.
  cat > "$SESSION_FILE" <<EOF
BACKUP_SESSION="$BACKUP_SESSION"
BACKUP_DIR="$BACKUP_DIR"
RESTORE_FILE="$RESTORE_FILE"
EOF

  # Initialize the RESTORE.txt file with a header.
  # We use a here-document (<<EOF) to write multiple lines at once.
  cat > "$RESTORE_FILE" <<EOF
Backup created: $(date '+%Y-%m-%d %H:%M:%S')
Source: dotfiles installation

Files backed up:
EOF

  # Check if a 'rollback.sh' script exists in the same directory as this script.
  # If it does, copy it to the backup directory. This script likely automates the restoration process.
  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$SCRIPT_DIR/rollback.sh" ]; then
    cp "$SCRIPT_DIR/rollback.sh" "$BACKUP_DIR/rollback.sh"
    chmod +x "$BACKUP_DIR/rollback.sh"
  fi

  # Create an empty file with a descriptive name to remind users to enable "Show Hidden Files".
  # This is helpful because dotfiles start with a dot (.) and are hidden by default in file managers.
  touch "$BACKUP_DIR/ENABLE-HIDDEN-FILES-VIEW.txt"

  # Output the session ID so the caller can use it or log it.
  echo "$BACKUP_SESSION"
}

# Function to backup a specific file or directory.
# Arguments: $1 - The absolute path of the file or directory to backup.
backup_file() {
  local source_path="$1"

  # Check if the BACKUP_DIR variable is set.
  # If not, try to load it from the session file.
  # This handles cases where backup_file is called from a sub-script that didn't call init_backup_session itself.
  if [ -z "$BACKUP_DIR" ]; then
    if [ ! -f "$SESSION_FILE" ]; then
      echo "ERROR: No backup session initialized" >&2
      return 1
    fi
    source "$SESSION_FILE"
  fi

  # Check if the source file exists. If not, there's nothing to backup, so we return error.
  if [ ! -e "$source_path" ]; then
    return 1
  fi

  # Calculate the relative path of the file (removing the leading slash).
  # Example: /home/user/.zshrc -> home/user/.zshrc
  local rel_path="${source_path#/}"  
  
  # Construct the full destination path inside the backup directory.
  local backup_path="$BACKUP_DIR/$rel_path"
  
  # Determine the parent directory of the backup destination.
  local backup_parent="$(dirname "$backup_path")"

  # Create the parent directory structure in the backup location.
  mkdir -p "$backup_parent" || {
    echo "ERROR: Failed to create backup directory: $backup_parent" >&2
    return 1
  }

  # Perform the copy operation.
  # We check if the source is inside the user's home directory to decide if we need sudo.
  if [[ "$source_path" =~ ^"$HOME" ]]; then
    # If it's in the home directory, we can copy it as the current user.
    # -r: Recursive (for directories).
    # -P: No-dereference (preserve symlinks as links, don't copy the target).
    cp -rP "$source_path" "$backup_path" || {
      echo "ERROR: Failed to backup: $source_path" >&2
      return 1
    }
  else
    # If it's outside the home directory (e.g., /etc/config), we need root privileges.
    sudo cp -rP "$source_path" "$backup_path" || {
      echo "ERROR: Failed to backup: $source_path" >&2
      return 1
    }
  fi

  # Generate the exact command needed to restore this specific file.
  # This makes manual restoration much safer and easier for the user.
  local rm_cmd cp_cmd restore_cmd
  
  if [ -d "$source_path" ]; then
    # If the source was a directory:
    # 1. Remove the current directory at the source path.
    # 2. Copy the backed-up directory back to the source location.
    rm_cmd="rm -rf \"$source_path\""
    cp_cmd="cp -rP \"$BACKUP_DIR/$rel_path\" \"$(dirname "$source_path")/\""
  else
    # If the source was a file:
    # 1. Remove the current file.
    # 2. Copy the backed-up file back.
    rm_cmd="rm -f \"$source_path\""
    cp_cmd="cp -P \"$BACKUP_DIR/$rel_path\" \"$source_path\""
  fi

  # If the file is outside the home directory, prepend 'sudo' to the restore commands.
  if [[ ! "$source_path" =~ ^"$HOME" ]]; then
    rm_cmd="sudo $rm_cmd"
    cp_cmd="sudo $cp_cmd"
  fi

  # Combine the remove and copy commands into a single restore string.
  restore_cmd="$rm_cmd && $cp_cmd"

  # Append the file path and its restore command to the RESTORE.txt file.
  cat >> "$RESTORE_FILE" <<EOF

- $source_path
  Restore: $restore_cmd
EOF

  # Return success.
  return 0
}
