{ lib, pkgs, ... }:

let
  version = "18.8.7";
  release = {
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-yFQlMO18tUzg7dasLLvauJLot0zXQAdGhtxtLFeGsPw=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-uH+YNaCs27gbu62Cc6otmZtgiiCFmEIalYTP/rMTmoo=";
    };
  }.${pkgs.stdenv.hostPlatform.system};

  oh-my-pi = pkgs.stdenvNoCC.mkDerivation {
    pname = "oh-my-pi";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${release.asset}";
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
      homepage = "https://github.com/can1357/oh-my-pi";
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
