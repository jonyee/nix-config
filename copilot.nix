{ config, lib, pkgs, ... }:

let
  # The umbrella npm package is only a loader; use the native Linux packages.
  sources = {
    aarch64-linux = { arch = "arm64"; hash = "sha256-XmjXpgYefISdOjdp+kI7L1HPLBYkTOh6+81B8U+Wj/0="; };
    x86_64-linux = { arch = "x64"; hash = "sha256-Nyw53szucrajPFeHGTaO5luvabWt6Ns6LYWzi+KQIJE="; };
  };
  source = sources.${pkgs.stdenv.hostPlatform.system};

  github-copilot-cli = pkgs.stdenv.mkDerivation rec {
    pname = "github-copilot-cli";
    version = "1.0.95";

    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@github/copilot-linux-${source.arch}/-/copilot-linux-${source.arch}-${version}.tgz";
      inherit (source) hash;
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 copilot $out/bin/copilot
      install -Dm644 LICENSE.md $out/share/licenses/github-copilot-cli/LICENSE.md

      runHook postInstall
    '';

    meta = {
      description = "GitHub Copilot CLI";
      license = lib.licenses.unfree;
      mainProgram = "copilot";
      platforms = builtins.attrNames sources;
    };
  };

  update-copilot = pkgs.writeShellScriptBin "update-copilot" ''
    set -euo pipefail
    CONFIG="$(dirname "$(readlink -f /etc/nixos/configuration.nix)")/copilot.nix"

    echo "Fetching latest version from npm..."
    LATEST=$(${pkgs.curl}/bin/curl -fsSL https://registry.npmjs.org/@github/copilot/latest | ${pkgs.jq}/bin/jq -er '.version')
    [[ "$LATEST" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid release version" >&2; exit 1; }

    CURRENT=$(${pkgs.gawk}/bin/awk '/pname = "github-copilot-cli"/{getline; gsub(/.*version = "|";/,""); print; exit}' "$CONFIG")

    echo "Current: $CURRENT"
    echo "Latest:  $LATEST"

    if [ "$CURRENT" = "$LATEST" ]; then
      echo "Already up to date!"
      exit 0
    fi

    echo "Prefetching native tarballs for both architectures..."
    prefetch() {
      local arch="$1" hash
      hash=$(nix-prefetch-url --unpack --type sha256 \
        "https://registry.npmjs.org/@github/copilot-linux-$arch/-/copilot-linux-$arch-''${LATEST}.tgz") || return "$?"
      nix-hash --to-sri --type sha256 "$hash"
    }
    # Fetch both successfully before changing the configuration.
    ARM64_HASH=$(prefetch arm64)
    X64_HASH=$(prefetch x64)

    ${pkgs.gnused}/bin/sed -i \
      -e "/pname = \"github-copilot-cli\";/{n;s|version = \"[^\"]*\"|version = \"$LATEST\"|;}" \
      -e "/aarch64-linux =/s|hash = \"[^\"]*\"|hash = \"$ARM64_HASH\"|" \
      -e "/x86_64-linux =/s|hash = \"[^\"]*\"|hash = \"$X64_HASH\"|" \
      "$CONFIG"

    echo ""
    echo "Updated copilot.nix:"
    echo "  version: $CURRENT -> $LATEST"
    echo "  arm64 hash: $ARM64_HASH"
    echo "  x64 hash:   $X64_HASH"
    echo ""
    echo "Run 'sudo nixos-rebuild switch' to apply."
  '';
in
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    github-copilot-cli
    update-copilot
  ];
}
