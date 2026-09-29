{ lib, pkgs, ... }:

let
  version = "0.9.1";
  release = {
    aarch64-linux = {
      asset = "herdr-linux-aarch64";
      hash = "sha256-9Mz03nRfLLmjmpg+m6NwPa1Q7CpY3qgwJs6rchu9jZ4=";
    };
    x86_64-linux = {
      asset = "herdr-linux-x86_64";
      hash = "sha256-KgL+0WvrZR7wBuHUPwSPZSyk3FitBTzS1ERQVj1cVLc=";
    };
  }.${pkgs.stdenv.hostPlatform.system};

  herdr = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/${release.asset}";
      inherit (release) hash;
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/herdr"
      runHook postInstall
    '';

    meta = {
      description = "Terminal workspace manager for AI coding agents";
      homepage = "https://herdr.dev";
      license = lib.licenses.asl20;
      mainProgram = "herdr";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [ "aarch64-linux" "x86_64-linux" ];
    };
  };
in
{
  environment.systemPackages = [ herdr ];
}
