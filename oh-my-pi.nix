{ lib, pkgs, ... }:

let
  version = "18.8.9-fork.2";
  releaseTag = "fork-v18.8.9-2";
  release = {
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-OOpKEYOYpOXaL6K23gXkyXgrFKbxxpe8TZRHKGy/wJA=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-z5C7sOm+siRMNLKy9nCWE+e8UVD9ej18AdX7l0Lt8lA=";
    };
  }.${pkgs.stdenv.hostPlatform.system};

  oh-my-pi = pkgs.stdenvNoCC.mkDerivation {
    pname = "oh-my-pi";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/jonyee/oh-my-pi/releases/download/${releaseTag}/${release.asset}";
      inherit (release) hash;
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      # Bun's bundled payload must remain unchanged; nix-ld supplies its ELF loader.
      install -Dm755 "$src" "$out/bin/omp"
      runHook postInstall
    '';

    meta = {
      description = "Coding agent with the IDE wired in";
      homepage = "https://github.com/jonyee/oh-my-pi";
      license = lib.licenses.mit;
      mainProgram = "omp";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "aarch64-linux" "x86_64-linux" ];
    };
  };
in
{
  environment.systemPackages = [ oh-my-pi ];
}
