{ config, lib, pkgs, ... }:

let
  version = "0.72.1";

  pi-npm-global = pkgs.stdenv.mkDerivation {
    name = "pi-coding-agent-npm-${version}";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-iOoEitzPFZPfWwtYz7JYcFX3T7gqy2xG2Rr79TgUROo=";
    nativeBuildInputs = [ pkgs.nodejs_22 pkgs.cacert ];
    buildCommand = ''
      export HOME="$TMPDIR"
      export npm_config_cache="$TMPDIR/.npm"
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      npm install -g --prefix="$out" @mariozechner/pi-coding-agent@${version}
      rm -rf "$out/bin"
    '';
  };

  pi-coding-agent = pkgs.stdenv.mkDerivation {
    pname = "pi-coding-agent";
    inherit version;
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      makeBinaryWrapper ${pkgs.nodejs_22}/bin/node $out/bin/pi \
        --add-flags "${pi-npm-global}/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js"
      runHook postInstall
    '';
    meta = {
      description = "Coding agent CLI with session management";
      license = lib.licenses.mit;
      mainProgram = "pi";
    };
  };

  update-pi-coding-agent = pkgs.writeShellScriptBin "update-pi-coding-agent" ''
    set -euo pipefail
    CONFIG_DIR="$(dirname "$(readlink -f /etc/nixos/configuration.nix)")"
    CONFIG="$CONFIG_DIR/pi-coding-agent.nix"
    TEMPLATE="$CONFIG_DIR/pi-hash-template.nix"

    echo "Fetching latest version from npm..."
    LATEST=$(${pkgs.curl}/bin/curl -s https://registry.npmjs.org/@mariozechner/pi-coding-agent/latest | ${pkgs.jq}/bin/jq -r '.version')
    CURRENT="${version}"

    echo "Current: $CURRENT"
    echo "Latest:  $LATEST"

    if [ "$CURRENT" = "$LATEST" ]; then
      echo "Already up to date!"
      exit 0
    fi

    echo "Prefetching npm dependencies for $LATEST (this may take a moment)..."
    BUILD_OUT=$(nix-build --no-out-link -E "(import $TEMPLATE \"$LATEST\")" 2>&1 || true)
    NEW_HASH=$(echo "$BUILD_OUT" | ${pkgs.gawk}/bin/awk '/got:/{print $2}')

    if [ -z "$NEW_HASH" ]; then
      echo "ERROR: Could not extract hash. Build output:"
      echo "$BUILD_OUT"
      exit 1
    fi

    echo "Hash: $NEW_HASH"

    ${pkgs.gnused}/bin/sed -i "s|version = \"${version}\"|version = \"$LATEST\"|" "$CONFIG"
    ${pkgs.gnused}/bin/sed -i "s|outputHash = \"sha256-[^\"]*\"|outputHash = \"$NEW_HASH\"|" "$CONFIG"

    echo ""
    echo "Updated pi-coding-agent.nix:"
    echo "  version: $CURRENT -> $LATEST"
    echo "  hash:    $NEW_HASH"
    echo ""
    echo "Run 'sudo nixos-rebuild switch' to apply."
  '';
in
{
  environment.sessionVariables.AZURE_OPENAI_BASE_URL = "https://ai-jonyee7246ai751339609690.cognitiveservices.azure.com/";

  environment.systemPackages = [
    pi-coding-agent
    update-pi-coding-agent
  ];
}
