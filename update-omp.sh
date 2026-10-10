#!/usr/bin/env bash

main() {
  set -euo pipefail

  local release_tag="" version switch=false config_dir system release_url arm64_hash x64_hash drv output
  while (( $# )); do
    case "$1" in
      --switch) switch=true ;;
      -h|--help)
        cat <<'EOF'
Usage: bash update-omp.sh [FORK_TAG|latest] [--switch]

Update oh-my-pi.nix with the fork release tag, version and both architecture
hashes, then build and smoke-test OMP's bundled workers for this machine.
Defaults to the latest stable release from jonyee/oh-my-pi.
FORK_TAG must have the form fork-v18.8.9-1.

--switch also runs sudo nixos-rebuild switch to activate the configuration.
Without it, the running system is unchanged. Restart OMP after switching.
EOF
        return 0
        ;;
      -*) printf 'Unknown option: %s\n' "$1" >&2; return 1 ;;
      *)
        if [[ -n "$release_tag" ]]; then
          printf 'Expected at most one version. Use --help for usage.\n' >&2
          return 1
        fi
        release_tag="$1"
        ;;
    esac
    shift
  done

  config_dir="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
  case "$(uname -m)" in
    aarch64) system=nixos-aarch64 ;;
    x86_64) system=nixos-x86_64 ;;
    *) printf 'Unsupported architecture: %s\n' "$(uname -m)" >&2; return 1 ;;
  esac

  release_url=https://github.com/jonyee/oh-my-pi/releases
  if [[ -z "$release_tag" || "$release_tag" == latest ]]; then
    release_tag="$(curl --fail --silent --show-error --head --location \
      --output /dev/null --write-out '%{url_effective}' "$release_url/latest")"
    release_tag="${release_tag##*/}"
  fi
  if [[ "$release_tag" =~ ^fork-v([0-9]+\.[0-9]+\.[0-9]+)-([1-9][0-9]*)$ ]]; then
    version="${BASH_REMATCH[1]}-fork.${BASH_REMATCH[2]}"
  else
    printf 'Invalid fork release tag: %s\n' "$release_tag" >&2
    return 1
  fi

  # Fetch both assets before changing the pin; a failed download leaves it intact.
  printf 'Fetching OMP %s for ARM64 and x86-64...\n' "$release_tag"
  arm64_hash="$(nix-prefetch-url --type sha256 "$release_url/download/$release_tag/omp-linux-arm64")"
  arm64_hash="$(nix hash convert --hash-algo sha256 --to sri "$arm64_hash")"
  x64_hash="$(nix-prefetch-url --type sha256 "$release_url/download/$release_tag/omp-linux-x64")"
  x64_hash="$(nix hash convert --hash-algo sha256 --to sri "$x64_hash")"

  sed -E -i \
    -e "s|^(  version = )\"[^\"]+\";|\1\"$version\";|" \
    -e "s|^(  releaseTag = )\"[^\"]+\";|\1\"$release_tag\";|" \
    -e "/^    aarch64-linux = \\{/,/^    \\};/ s|^(      hash = )\"[^\"]+\";|\1\"$arm64_hash\";|" \
    -e "/^    x86_64-linux = \\{/,/^    \\};/ s|^(      hash = )\"[^\"]+\";|\1\"$x64_hash\";|" \
    "$config_dir/oh-my-pi.nix"
  printf 'Updated %s to OMP %s. Building for %s...\n' "$config_dir/oh-my-pi.nix" "$version" "$system"

  drv="$(nix eval --raw --no-write-lock-file \
    "$config_dir#nixosConfigurations.$system.config.environment.systemPackages" \
    --apply 'packages: (builtins.head (builtins.filter (package: (package.pname or "") == "oh-my-pi") packages)).drvPath')"
  output="$(nix build --no-link --print-out-paths "$drv^out")"
  "$output/bin/omp" --version
  "$output/bin/omp" --smoke-test

  if [[ "$switch" == true ]]; then
    sudo nixos-rebuild switch --flake "$config_dir#$system"
    printf 'Configuration activated. Exit and relaunch OMP to use the new version.\n'
  else
    printf 'Build verified; the running system is unchanged.\n'
    printf 'To activate: sudo nixos-rebuild switch --flake %q\n' "$config_dir#$system"
  fi
}

main "$@"
