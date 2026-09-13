#!/usr/bin/env bash

main() {
  set -euo pipefail

  local config_dir="$HOME/git/nix-config" system path
  case "$(uname -m)" in
    aarch64) system=nixos-aarch64 ;;
    x86_64) system=nixos-x86_64 ;;
    *) printf 'Unsupported architecture: %s\n' "$(uname -m)" >&2; return 1 ;;
  esac

  for path in "$config_dir" /etc/nixos.initial; do
    if [[ -e "$path" || -L "$path" ]]; then
      printf 'Refusing to overwrite %s; this installer requires a fresh instance.\n' "$path" >&2
      return 1
    fi
  done

  mkdir -p "$HOME/git"
  config_dir="$config_dir" nix-shell -p git --run \
    "git clone --depth 1 https://github.com/jonyee/nix-config.git \"\$config_dir\""
  sudo mv /etc/nixos /etc/nixos.initial
  sudo mkdir -p /etc/nixos
  sudo ln -s "$config_dir/configuration.nix" /etc/nixos/configuration.nix
  sudo env NIX_CONFIG='experimental-features = nix-command flakes' \
    nixos-rebuild switch --flake "$config_dir#$system"
}

main
