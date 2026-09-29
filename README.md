# NixOS-WSL configuration

Once this repository is public and the installer is published on `main`, run this command as the normal user in a fresh NixOS-WSL instance:

```bash
curl -fsSL https://raw.githubusercontent.com/jonyee/nix-config/main/install.sh | bash
```

The installer supports ARM64 and x86-64 and refuses to overwrite an existing `~/git/nix-config` or `/etc/nixos.initial`.

The repository remains at `~/git/nix-config`, with `/etc/nixos/configuration.nix` linked to it for compatibility. The original NixOS-WSL configuration remains at `/etc/nixos.initial`. Open a new terminal after the rebuild to start the configured Fish shell.

## Azure CLI

The system configuration installs Azure CLI (`az`) from the pinned nixpkgs input for ARM64 and x86-64. After activating the configuration, run `az --version` to check the installation. Sign in with `az login` when needed; credentials are not part of this configuration.
