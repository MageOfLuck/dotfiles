#!/usr/bin/env bash
set -e

info() { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[✓]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { warn "$*"; exit 1; }

dotfiles_dir="${HOME:?Set HOME before running this script}/.dotfiles"
command -v stow >/dev/null || die "GNU Stow is required. Install the stow package first."
[[ -d $dotfiles_dir ]] || die "Dotfiles directory is missing: $dotfiles_dir"

qt6ct_package=Qt6ct
if [[ ! -d $dotfiles_dir/Qt6ct && -d $dotfiles_dir/qt6ct ]]; then
    qt6ct_package=qt6ct
fi

# Each entry pairs a package directory with its Stow target.
packages=(
    "hypr:$HOME/.config/hypr"
    "swappy:$HOME/.config/swappy"
    "vicinae:$HOME/.config/vicinae"
    "starship:$HOME/.config"
    "wezterm:$HOME/.config/wezterm"
    "bin:$HOME/.local/bin"
    "vicinae-themes:$HOME/.local/share/vicinae/themes"
    "zsh:$HOME"
    "quickshell:$HOME/.config/quickshell"
    "$qt6ct_package:$HOME/.config/qt6ct/colors"
)

info "Stowing dotfiles from $dotfiles_dir..."
for entry in "${packages[@]}"; do
    IFS=: read -r package target <<< "$entry"
    package_dir="$dotfiles_dir/$package"
    [[ -d $package_dir ]] || die "Missing Stow package: $package_dir"
    mkdir -p -- "$target"

    backup=
    hypr_lua="$target/hyprland.lua"
    # Back up the existing file only when the Hyprland package supplies a replacement.
    if [[ $package == hypr && -f $package_dir/hyprland.lua &&
          -f $hypr_lua && ! -L $hypr_lua && ! $hypr_lua -ef $package_dir/hyprland.lua ]]; then
        backup=$(mktemp -- "$hypr_lua.bak.XXXXXX")
        if ! mv -T -- "$hypr_lua" "$backup"; then
            rm -f -- "$backup"
            die "Could not back up $hypr_lua."
        fi
        warn "Backed up $hypr_lua to $backup"
    fi

    if stow -d "$dotfiles_dir" -t "$target" "$package"; then
        ok "$package -> $target"
    else
        status=$?
        if [[ -n $backup && ! -e $hypr_lua && ! -L $hypr_lua ]]; then
            if mv -nT -- "$backup" "$hypr_lua" && [[ ! -e $backup ]]; then
                warn "Restored $hypr_lua after Stow failed."
            else
                warn "Could not restore $hypr_lua. The backup is at $backup."
            fi
        fi
        warn "Could not stow $package into $target."
        exit "$status"
    fi
done