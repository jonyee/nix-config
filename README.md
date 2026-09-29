# NixOS-WSL configuration

Once this repository is public and the installer is published on `main`, run this command as the normal user in a fresh NixOS-WSL instance:

```bash
curl -fsSL https://raw.githubusercontent.com/jonyee/nix-config/main/install.sh | bash
```

The installer supports ARM64 and x86-64 and refuses to overwrite an existing `~/git/nix-config` or `/etc/nixos.initial`.

The repository remains at `~/git/nix-config`, with `/etc/nixos/configuration.nix` linked to it for compatibility. The original NixOS-WSL configuration remains at `/etc/nixos.initial`. Open a new terminal after the rebuild to start the configured Fish shell.

## Azure CLI

The system configuration installs Azure CLI (`az`) from the pinned nixpkgs input for ARM64 and x86-64. After activating the configuration, run `az --version` to check the installation. Sign in with `az login` when needed; credentials are not part of this configuration.

## Pi coding agent

The system configuration installs [Pi](https://pi.dev/) as `pi` on ARM64 and x86-64, independently of `omp`. Its package comes from the pinned [pi.nix](https://github.com/lukasl-dev/pi.nix) flake; no installer or global npm install is needed. After activating the configuration, run `pi --version`, then `pi` in your project directory. Use `/login` inside Pi to connect a provider; keep credentials outside this repository.

To upgrade Pi, run `nix flake update pi` in this repository, build the configuration, and then activate it. Updating the pinned input does not change the running system until activation.

## Herdr

The system configuration installs Herdr from pinned Linux ARM64 and x86-64 release binaries in `herdr.nix`. After activating the configuration, run `herdr` to start or attach to a persistent terminal session; `Ctrl+b q` detaches without stopping it. Update the version and both hashes in `herdr.nix` before rebuilding to upgrade Herdr. Use the configured package rather than `herdr update` so upgrades remain declarative.

## Updating OMP

Fetch the latest stable release, update the version and both architecture hashes in `oh-my-pi.nix`, build OMP for this machine, smoke-test its bundled workers, and activate the configuration:

```sh
bash "$HOME/git/nix-config/update-omp.sh" --switch
```

Omit `--switch` to update the pin and verify the build without changing the running system. To select a specific release instead of the latest:

```sh
bash "$HOME/git/nix-config/update-omp.sh" 18.1.22 --switch
```

The script works from any directory and requires Bash, curl, and Nix with `nix-command` and `flakes` enabled, as configured here. Both release assets must download successfully before the pin is changed. A later build or activation failure leaves the updated pin in place so it can be inspected or retried.

Switching applies the entire NixOS configuration, including any other pending edits. Exit and relaunch OMP afterward. Updating flake inputs alone does not change this separately pinned package.

OMP uses its own executable to launch the daemon broker and other workers. The package installs the release binary directly (not through a dynamic-linker wrapper); `programs.nix-ld.enable` supplies its loader on NixOS. After activation, run `omp --smoke-test` if troubleshooting worker startup.
