#!/usr/bin/env bash
set -e

info() { printf '%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

if [[ ${1-} == --help || ${1-} == -h ]]; then
    printf 'Usage: %s\n' "${0##*/}"
    printf '%s\n' \
        'Restore packages from pkglist.txt and aurpacks.txt next to this script.' \
        'Move visible sibling folders into ~/.dotfiles if that directory does not exist.' \
        'Skip the move when this script is already in a .dotfiles directory.'
    exit 0
fi

(( $# == 0 )) || die "Run this script without folder arguments. Use --help for details."
(( EUID != 0 )) || die "Run this as your normal user. The script calls sudo for pacman."
command -v pacman >/dev/null || die "This script requires pacman."
command -v sudo >/dev/null || die "This script requires sudo."

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
dotfiles_dir="${HOME:?Set HOME before running this script}/.dotfiles"

read_package_list() {
    local file=$1 line
    local -n packages=$2
    local package_pattern='^[[:space:]]*([[:alnum:]_@+][[:alnum:]_@.+-]*)[[:space:]]*$'

    if [[ ! -e $file ]]; then
        warn "Missing $file. Skipping that package list."
        return
    fi
    [[ -f $file && -r $file ]] || die "Cannot read package list $file."
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%%#*}
        [[ $line =~ ^[[:space:]]*$ ]] && continue
        [[ $line =~ $package_pattern ]] || die "Invalid package entry in $file: $line"
        packages+=("${BASH_REMATCH[1]}")
    done < "$file"
}

repo_packages=()
aur_packages=()
read_package_list "$script_dir/pkglist.txt" repo_packages
read_package_list "$script_dir/aurpacks.txt" aur_packages
(( ${#repo_packages[@]} + ${#aur_packages[@]} > 0 )) ||
    die "No packages were listed. Put pkglist.txt or aurpacks.txt next to this script."

info "Updating the system..."
sudo pacman -Syu --noconfirm

if (( ${#repo_packages[@]} > 0 )); then
    info "Checking pkglist.txt against the enabled repositories..."
    available_packages=$(pacman -Slq)
    [[ -n $available_packages ]] || die "pacman returned an empty repository package list."
    declare -A available=()
    while IFS= read -r package; do
        [[ -n $package ]] && available["$package"]=1
    done <<< "$available_packages"

    repo_targets=()
    for package in "${repo_packages[@]}"; do
        if [[ ${available[$package]+found} ]]; then
            repo_targets+=("$package")
        else
            warn "Unavailable in the enabled repositories, skipping: $package"
        fi
    done
    if (( ${#repo_targets[@]} > 0 )); then
        info "Installing repository packages..."
        sudo pacman -S --needed -- "${repo_targets[@]}"
    fi
fi

if (( ${#aur_packages[@]} > 0 )); then
    if ! command -v paru >/dev/null; then
        info "Installing paru from the enabled repositories..."
        sudo pacman -S --needed -- paru ||
            die "Could not install paru. Check the pacman output and your CachyOS repositories."
    fi
    info "Installing AUR packages..."
    paru -S --needed "${aur_packages[@]}"
fi

if zsh_path=$(command -v zsh); then
    passwd_entry=$(getent passwd "$EUID")
    if [[ ! ${passwd_entry##*:} -ef $zsh_path ]]; then
        info "Changing your login shell to $zsh_path..."
        chsh -s "$zsh_path"
    fi
else
    warn "zsh is unavailable. Your login shell was left as-is."
fi

if [[ ${script_dir##*/} == .dotfiles || $script_dir -ef $dotfiles_dir ]]; then
    info "Already in $script_dir. Skipping the folder move."
elif [[ -d $dotfiles_dir ]]; then
    info "Already have $dotfiles_dir. Skipping the folder move."
else
    mkdir -- "$dotfiles_dir"
    shopt -s nullglob
    for folder in "$script_dir"/*/; do
        folder=${folder%/}
        target_dir="$dotfiles_dir/${folder##*/}"
        mv -nT -- "$folder" "$target_dir"
        [[ ! -e $folder && ! -L $folder ]] ||
            die "Could not move $folder. Check $target_dir."
    done
fi

info "Rebuild complete."