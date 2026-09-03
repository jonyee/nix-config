# NixOS-WSL configuration

From a terminal in a fresh NixOS-WSL instance, paste this script:

```bash
set -euo pipefail
repo=https://github.com/jonyee/nix-config.git
config_dir="$HOME/git/nix-config"
mkdir -p "$(dirname "$config_dir")"
nix-shell -p git --run "git clone --depth 1 '$repo' '$config_dir'"
case "$(uname -m)" in
  aarch64) system=nixos-aarch64 ;;
  x86_64) system=nixos-x86_64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
sudo mv /etc/nixos /etc/nixos.initial
sudo mkdir -p /etc/nixos
sudo ln -s "$config_dir/configuration.nix" /etc/nixos/configuration.nix
sudo env NIX_CONFIG='experimental-features = nix-command flakes' \
  nixos-rebuild switch --flake "$config_dir#$system"
```

The repository remains at `~/git/nix-config`, with `/etc/nixos/configuration.nix` linked to it for compatibility. The original NixOS-WSL configuration remains at `/etc/nixos.initial`. Open a new terminal after the rebuild to start the configured Fish shell.

## Migrating an existing instance

The upstream installer puts a standalone `omp` binary at `~/.local/bin/omp`, which takes precedence over the NixOS package. From this repository, rebuild and remove only that legacy binary:

```bash
set -euo pipefail
cd "$HOME/git/nix-config"
case "$(uname -m)" in
  aarch64) system=nixos-aarch64 ;;
  x86_64) system=nixos-x86_64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
sudo nixos-rebuild switch --flake ".#$system"
rm -f "$HOME/.local/bin/omp"
hash -r
omp --version
```

This leaves OMP's configuration, credentials, sessions, and history under `~/.omp` unchanged.
