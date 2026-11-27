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

stow_package() {
    local package_dir="$dotfiles_dir/$1" target="$2" config_file="${3:-}"
    local stow_dir="${package_dir%/*}" package="${package_dir##*/}"
    local config_path="$target/$config_file" backup= status

    [[ -d $package_dir ]] || die "Missing Stow package: $package_dir"
    mkdir -p -- "$target"

    # Back up a standalone config file when the package supplies its replacement.
    if [[ -n $config_file && -f $package_dir/$config_file &&
          -f $config_path && ! -L $config_path && ! $config_path -ef $package_dir/$config_file ]]; then
        backup=$(mktemp -- "$config_path.bak.XXXXXX")
        if ! mv -T -- "$config_path" "$backup"; then
            rm -f -- "$backup"
            die "Could not back up $config_path."
        fi
        warn "Backed up $config_path to $backup"
    fi

    if stow -d "$stow_dir" -t "$target" "$package"; then
        ok "$1 -> $target"
    else
        status=$?
        if [[ -n $backup && ! -e $config_path && ! -L $config_path ]]; then
            if mv -nT -- "$backup" "$config_path" && [[ ! -e $backup ]]; then
                warn "Restored $config_path after Stow failed."
            else
                warn "Could not restore $config_path. The backup is at $backup."
            fi
        fi
        warn "Could not stow $1 into $target."
        exit "$status"
    fi
}

info "Stowing dotfiles from $dotfiles_dir..."
stow_package hypr "$HOME/.config/hypr" hyprland.lua
stow_package swappy "$HOME/.config/swappy"
stow_package vicinae/vicinae-config "$HOME/.config/vicinae" settings.json
stow_package starship "$HOME/.config"
stow_package wezterm "$HOME/.config/wezterm"
stow_package bin "$HOME/.local/bin"
stow_package vicinae/vicinae-themes "$HOME/.local/share/vicinae/themes"
stow_package zsh "$HOME"
stow_package quickshell "$HOME/.config/quickshell"
stow_package "$qt6ct_package" "$HOME/.config/qt6ct/colors"
stow_package vscodium/vscodium-config "$HOME/.config/VSCodium/User" settings.json

extensions_dir="$dotfiles_dir/vscodium"
extensions_list="$extensions_dir/codium.txt"
theme_vsix="$extensions_dir/quickshell-mocha.vsix"

command -v codium >/dev/null || die "VSCodium is required to install extensions."
[[ -f $theme_vsix && -r $theme_vsix ]] || die "Cannot read theme package: $theme_vsix"
[[ -f $extensions_list && -r $extensions_list ]] || die "Cannot read extension list: $extensions_list"

info "Installing VSCodium extensions..."
codium --install-extension "$theme_vsix"

while IFS= read -r -u 3 extension || [[ -n $extension ]]; do
    [[ -n $extension && $extension != local-themes.quickshell-mocha ]] || continue
    codium --install-extension "$extension"
done 3< "$extensions_list"

install_dj_fox_cursor() (
    local theme=DJ-FOX-C
    local icons_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local theme_dir="$icons_dir/$theme"

    command -v python3 >/dev/null || die "Python 3 is required to set up $theme."
    if [[ ! -f $theme_dir/index.theme || ! -f $theme_dir/cursors/left_ptr ]]; then
        [[ ! -e $theme_dir && ! -L $theme_dir ]] || die "Existing cursor theme is incomplete: $theme_dir"
        command -v curl >/dev/null || die "curl is required to download $theme."
        mkdir -p -- "$icons_dir"

        local work_dir archive download_url
        work_dir=$(mktemp -d -- "$icons_dir/.dj-fox-c.XXXXXX")
        trap 'rm -rf -- "$work_dir"' EXIT
        archive="$work_dir/$theme.tar.gz"
        local -a curl_options=(--fail --silent --show-error --location --proto '=https'
            --proto-redir '=https' --connect-timeout 10 --max-time 120 --retry 2)

        info "Downloading $theme from OpenDesktop..."
        curl "${curl_options[@]}" --header 'Cache-Control: no-cache' \
            --output "$work_dir/metadata.json" \
            'https://api.opendesktop.org/ocs/v1/content/data/2113007?format=json' \
            || die "Could not fetch the $theme download listing."
        download_url=$(python3 - "$work_dir/metadata.json" "$theme.tar.gz" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as metadata:
    listing = json.load(metadata)

for item in listing["data"]:
    for key, name in item.items():
        if key.startswith("downloadname") and name == sys.argv[2]:
            link = item["downloadlink" + key.removeprefix("downloadname")]
            if link.startswith("https://"):
                print(link)
                sys.exit(0)
sys.exit("The Linux cursor archive is missing from the OpenDesktop listing.")
PY
        ) || die "Could not find the $theme archive."
        curl "${curl_options[@]}" --output "$archive" "$download_url" \
            || die "Could not download $theme."

        # Pin the upstream archive that contains both XCursor and Hyprcursor assets.
        local checksum=7224709e0d09ea49a0124d12027e6f2d8d372345255cfc94529dd450f913ea7d
        if ! (cd -- "$work_dir" && printf '%s  %s\n' "$checksum" "$theme.tar.gz" | sha256sum --check --status); then
            die "The $theme archive did not match its expected SHA-256."
        fi
        tar --extract --gzip --file "$archive" --directory "$work_dir" \
            --no-same-owner --no-same-permissions
        mv -nT -- "$work_dir/$theme" "$theme_dir"
        [[ -f $theme_dir/index.theme && -f $theme_dir/cursors/left_ptr ]] \
            || die "Could not install $theme at $theme_dir."
    fi

    # Update only the cursor keys and keep existing settings, comments, and symlinks.
    python3 - "$config_dir" "$icons_dir" "$theme" <<'PY'
import re
import stat
import sys
import tempfile
from pathlib import Path


def set_ini_key(path, section, key, value):
    path = path.resolve()
    original = path.read_bytes().decode("utf-8") if path.exists() else ""
    newline = "\r\n" if "\r\n" in original else "\n"
    lines = original.splitlines(keepends=True)
    groups = [i for i, line in enumerate(lines) if re.fullmatch(r"\s*\[[^\]]+\]\s*", line)]
    group = next((i for i in reversed(groups) if lines[i].strip() == f"[{section}]"), None)
    entry = f"{key}={value}{newline}"

    if group is None:
        separator = newline if original and not original.endswith("\n") else ""
        updated = original + separator + f"[{section}]{newline}" + entry
    else:
        end = next((i for i in groups if i > group), len(lines))
        setting = re.compile(rf"^([ \t]*{re.escape(key)}[ \t]*=[ \t]*)[^\r\n]*")
        key_indices = [i for i in range(group + 1, end) if setting.match(lines[i])]
        if key_indices:
            for i in key_indices:
                lines[i] = setting.sub(lambda match: match[1] + value, lines[i], count=1)
        else:
            if not lines[group].endswith("\n"):
                lines[group] += newline
            lines.insert(group + 1, entry)
        updated = "".join(lines)

    if updated == original:
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o644
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as temporary:
        temporary_path = Path(temporary.name)
        try:
            temporary.write(updated.encode("utf-8"))
            temporary.flush()
            temporary_path.chmod(mode)
            temporary_path.replace(path)
        finally:
            temporary_path.unlink(missing_ok=True)


config_dir, icons_dir = map(Path, sys.argv[1:3])
theme = sys.argv[3]
for version in ("gtk-3.0", "gtk-4.0"):
    set_ini_key(config_dir / version / "settings.ini", "Settings", "gtk-cursor-theme-name", theme)

fallback = icons_dir / "default" / "index.theme"
if fallback.parent.is_symlink() or fallback.is_symlink():
    print(f"Keeping the existing XCursor fallback symlink for {fallback}.", file=sys.stderr)
else:
    set_ini_key(fallback, "Icon Theme", "Inherits", theme)
PY

    if command -v gsettings >/dev/null &&
        gsettings get org.gnome.desktop.interface cursor-theme >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface cursor-theme "'$theme'" \
            || warn "Could not set the GTK cursor through GSettings."
    fi

    ok "$theme -> $theme_dir"
)

install_dj_fox_cursor