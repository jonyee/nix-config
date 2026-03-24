{ config, lib, pkgs, ... }:

let
  github-copilot-cli = pkgs.stdenv.mkDerivation rec {
    pname = "github-copilot-cli";
    version = "1.0.11";

    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
      hash = "sha256:0wzf68s4751kgrhip2wcqvwprgz9kdcw1yz55mj31vwqk188wfxi";
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
    CONFIG="/etc/nixos/configuration.nix"

    echo "Fetching latest version from npm..."
    LATEST=$(${pkgs.curl}/bin/curl -s https://registry.npmjs.org/@github/copilot/latest | ${pkgs.jq}/bin/jq -r '.version')

    CURRENT=$(${pkgs.gnugrep}/bin/grep -A1 'pname = "github-copilot-cli"' "$CONFIG" | ${pkgs.gnugrep}/bin/grep -oP 'version = "\K[^"]+')

    echo "Current: $CURRENT"
    echo "Latest:  $LATEST"

    if [ "$CURRENT" = "$LATEST" ]; then
      echo "Already up to date!"
      exit 0
    fi

    echo "Prefetching new tarball..."
    URL="https://registry.npmjs.org/@github/copilot/-/copilot-''${LATEST}.tgz"
    HASH=$(nix-prefetch-url --unpack --type sha256 "$URL" 2>/dev/null)
    SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

    echo "New hash: $SRI_HASH"

    ${pkgs.gnused}/bin/sed -i \
      "/pname = \"github-copilot-cli\";/{n;s|version = \"[^\"]*\"|version = \"$LATEST\"|}" \
      "$CONFIG"

    ${pkgs.gnused}/bin/sed -i \
      "/registry.npmjs.org\/@github\/copilot/{n;s|hash = \"[^\"]*\"|hash = \"$SRI_HASH\"|}" \
      "$CONFIG"

    echo ""
    echo "Updated configuration.nix:"
    echo "  version: $CURRENT -> $LATEST"
    echo "  hash:    $SRI_HASH"
    echo ""
    echo "Run 'sudo nixos-rebuild switch' to apply."
  '';
in
{
  imports = [
    <nixos-wsl/modules>
  ];
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    github-copilot-cli
    update-copilot
    pkgs.git
    pkgs.fish
    pkgs.fishPlugins.bobthefish
  ];

  programs.fish.enable = true;

  users.defaultUserShell = pkgs.fish;

  system.stateVersion = "25.11";
}
