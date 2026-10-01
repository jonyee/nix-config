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

### Nix-managed extensions

`pi.nix` uses the pinned flake's NixOS module and loads these extensions for every Pi session:

- `pi-mcp-adapter` 4.0.0
- `pi-powerline-footer` 0.19.0
- `pi-web-access` 0.35.0

Powerline activates automatically after activation and restarting Pi. Use `/powerline` to toggle it or `/powerline ascii` for a font-independent preset. Preferences remain in your runtime Pi settings, outside this repository.

Their versions and transitive dependencies are pinned in `pi-extensions/package.json` and `pi-extensions/package-lock.json`. Nix installs them into the store at build time, disables npm lifecycle scripts and automatic peer installation, and patches native Linux dependencies. Launching Pi does not install these extensions with npm. Provider credentials, MCP server configuration, extension preferences, and sessions remain in your runtime configuration outside the repository.

When migrating another installation, remove any previous npm declarations for these extensions after activation to avoid loading both the npm and Nix copies. For example, if web access was installed at user scope and the MCP adapter at project scope:

```sh
pi remove npm:pi-web-access
# From this repository:
pi remove --local npm:pi-mcp-adapter@4.0.0
```

These commands remove the old package declarations/installations, not the Nix-managed extensions. Existing settings are not automatically rewritten by this configuration. `pi list` lists settings-managed packages, not the extensions passed by the Nix wrapper; use `pi --verbose` to inspect the startup resource list.

To update an extension, edit its exact version in `pi-extensions/package.json`, then regenerate the lockfile:

```sh
npm install --prefix pi-extensions --package-lock-only --ignore-scripts --legacy-peer-deps --no-audit --no-fund
```

Update `npmDepsHash` in `pi.nix` for the new lockfile (temporarily use `pkgs.lib.fakeHash`, build the package, and replace it with the reported hash). Evaluate both NixOS configurations, build and smoke-test the configured Pi package, then activate and restart Pi. Do not use `pi update --extensions` to upgrade the Nix-managed copies.

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
