#!/usr/bin/env bash

set -euo pipefail

if (( EUID == 0 )); then
  printf 'Run this script as a normal user.\n' >&2
  exit 1
fi

flathub_repo='https://dl.flathub.org/repo/flathub.flatpakrepo'
system_apps=(
  'cc.arduino.IDE2//stable'
  'cc.arduino.arduinoide//stable'
  'net.kuribo64.melonDS//stable'
  'net.rpcs3.RPCS3//stable'
  'org.flatpak.Builder//stable'
  'org.vinegarhq.Sober//stable'
)

deadlock_app='dev.stormix.deadlock-mod-manager'
deadlock_bundle='deadlock-mod-manager-cef.flatpak'
deadlock_release='https://github.com/deadlock-mod-manager/deadlock-mod-manager/releases/download/v2.3.0'
deadlock_sha256='b08ac6f26252aa15068257e8e142c950908195843d9bd3fa2f512e298bb9a496'

if ! command -v flatpak >/dev/null 2>&1; then
  sudo pacman -S --needed flatpak
fi

printf 'Installing system-wide Flatpaks from Flathub.\n'
sudo flatpak remote-add --system --if-not-exists flathub "$flathub_repo"
sudo flatpak install --system --assumeyes --app flathub "${system_apps[@]}"

printf 'Installing Bottles for %s.\n' "$(id -un)"
flatpak remote-add --user --if-not-exists flathub "$flathub_repo"
flatpak install --user --assumeyes --app flathub 'com.usebottles.bottles//stable'

if flatpak info --user "$deadlock_app" master >/dev/null 2>&1; then
  printf 'Deadlock Mod Manager is already installed.\n'
else
  printf 'Installing Deadlock Mod Manager 2.3.0 for %s.\n' "$(id -un)"
  download_dir=$(mktemp -d)
  trap 'rm -rf -- "$download_dir"' EXIT
  bundle_path="$download_dir/$deadlock_bundle"

  curl --fail --location --retry 3 --output "$bundle_path" "$deadlock_release/$deadlock_bundle"
  printf '%s  %s\n' "$deadlock_sha256" "$bundle_path" | sha256sum --check --quiet
  flatpak install --user --assumeyes --bundle "$bundle_path"
fi

printf 'Flatpak setup complete.\n'