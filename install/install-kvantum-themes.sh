#!/bin/bash

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "$SCRIPT_DIR/lib/helpers.sh"

DOTFILES_DIR="$HOME/.local/share/dotfiles"
TEMP_DIR=$(mktemp -d)

log_info "Downloading Kvantum themes..."

# Function to install a theme
# Usage: install_theme <repo_url> <source_path_in_repo> <target_theme_name> [kvconfig_pattern]
install_theme() {
    local repo_url="$1"
    local source_path="$2"
    local target_name="$3"
    local pattern="${4:-*.kvconfig}"
    local repo_name=$(basename "$repo_url" .git)

    log_step "Installing $target_name from $repo_name..."

    # Clone repo to temp dir
    if [ ! -d "$TEMP_DIR/$repo_name" ]; then
        git clone --depth 1 "$repo_url" "$TEMP_DIR/$repo_name" &> /dev/null
    fi

    local full_source_path="$TEMP_DIR/$repo_name/$source_path"
    local target_dir="$DOTFILES_DIR/themes/$target_name"

    if [ ! -d "$target_dir" ]; then
        log_error "Target theme directory not found: $target_dir"
        return
    fi

    # Find the .kvconfig and .svg files
    local kvconfig=$(find "$full_source_path" -name "$pattern" | head -n 1)
    # If specific pattern didn't find anything, try generic
    if [ -z "$kvconfig" ]; then
        kvconfig=$(find "$full_source_path" -name "*.kvconfig" | head -n 1)
    fi
    
    local svg=$(find "$full_source_path" -name "*.svg" | head -n 1)

    if [ -n "$kvconfig" ]; then
        cp "$kvconfig" "$target_dir/kvantum.kvconfig"
        log_detail "Copied kvconfig: $(basename "$kvconfig")"
    else
        log_error "No .kvconfig found in $full_source_path matching $pattern"
    fi

    if [ -n "$svg" ]; then
        cp "$svg" "$target_dir/kvantum.svg"
        log_detail "Copied svg"
    else
        log_detail "No .svg found (might be code-only theme)"
    fi
}

# 1. Catppuccin (Mocha Blue) -> catppuccin
install_theme "https://github.com/catppuccin/kvantum.git" "themes/catppuccin-mocha-blue" "catppuccin"

# 2. Nord -> nord
install_theme "https://github.com/tonyfettes/materia-nord-kvantum.git" "Kvantum/MateriaNordDark" "nord"

# 3. Everforest -> everforest
install_theme "https://github.com/binEpilo/materia-everforest-kvantum.git" "MateriaEverforestDark" "everforest"

# 4. Tokyo Night -> osaka-jade (closest match)
install_theme "https://github.com/0xsch1zo/Kvantum-Tokyo-Night.git" "Kvantum-Tokyo-Night" "osaka-jade"

# 5. Gruvbox -> ristretto (closest match)
install_theme "https://github.com/TheSerphh/Gruvbox-Kvantum.git" "gruvbox-kvantum" "ristretto"

# 6. Matte Black -> matte-black (Using Graphite Dark)
install_theme "https://github.com/vinceliuice/Graphite-kde-theme.git" "Kvantum/Graphite" "matte-black" "*Dark.kvconfig"


log_success "Kvantum themes installed!"
rm -rf "$TEMP_DIR"
