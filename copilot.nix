{ config, lib, pkgs, ... }:

let
  github-copilot-cli = pkgs.stdenv.mkDerivation rec {
    pname = "github-copilot-cli";
    version = "1.0.27";

    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
      hash = "sha256-9bEsmQT31PN2kelXHwHFKXh7w9AkxTbSKKs1jswJrqc=";
    };

    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/node_modules/@github/copilot
      cp -r . $out/lib/node_modules/@github/copilot

      mkdir -p $out/bin
      makeBinaryWrapper ${pkgs.nodejs}/bin/node $out/bin/copilot \
        --add-flags "$out/lib/node_modules/@github/copilot/index.js"

      runHook postInstall
    '';

    meta = {
      description = "GitHub Copilot CLI";
      license = lib.licenses.unfree;
      mainProgram = "copilot";
    };
  };

  update-copilot = pkgs.writeShellScriptBin "update-copilot" ''
    set -euo pipefail
    CONFIG="$(dirname "$(readlink -f /etc/nixos/configuration.nix)")/copilot.nix"

    echo "Fetching latest version from npm..."
    LATEST=$(${pkgs.curl}/bin/curl -s https://registry.npmjs.org/@github/copilot/latest | ${pkgs.jq}/bin/jq -r '.version')

    CURRENT=$(${pkgs.gawk}/bin/awk '/pname = "github-copilot-cli"/{getline; gsub(/.*version = "|";/,""); print; exit}' "$CONFIG")

    echo "Current: $CURRENT"
    echo "Latest:  $LATEST"

    if [ "$CURRENT" = "$LATEST" ]; then
      echo "Already up to date!"
      exit 0
    fi

    echo "Prefetching new tarball..."
    URL="https://registry.npmjs.org/@github/copilot/-/copilot-''${LATEST}.tgz"
    HASH=$(nix-prefetch-url --unpack --type sha256 "$URL" 2>/dev/null)
    SRI_HASH=$(nix-hash --to-sri --type sha256 "$HASH")

    echo "New hash: $SRI_HASH"

    ${pkgs.gnused}/bin/sed -i \
      "/pname = \"github-copilot-cli\";/{n;s|version = \"[^\"]*\"|version = \"$LATEST\"|}" \
      "$CONFIG"

    ${pkgs.gnused}/bin/sed -i \
      "/registry.npmjs.org\/@github\/copilot/{n;s|hash = \"[^\"]*\"|hash = \"$SRI_HASH\"|}" \
      "$CONFIG"

    echo ""
    echo "Updated copilot.nix:"
    echo "  version: $CURRENT -> $LATEST"
    echo "  hash:    $SRI_HASH"
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
