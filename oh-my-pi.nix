{ lib, pkgs, ... }:

let
  version = "18.8.9-fork.1";
  releaseTag = "fork-v18.8.9-1";
  release = {
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-y5+zSHWnQimgWwzlqk3WN8ZO+a9DReyqksBxGb7+Id8=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-5xGSTwG4sanTpizGumhCz35KxdGZLzwje27sJ+2HMmE=";
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
