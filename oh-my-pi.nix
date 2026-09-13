{ lib, pkgs, ... }:

let
  version = "18.1.19";
  release = {
    aarch64-linux = {
      asset = "omp-linux-arm64";
      hash = "sha256-syG2uyqWBo3y9JcvmGVMI+RRNxonXPuwqY729fhY8jk=";
    };
    x86_64-linux = {
      asset = "omp-linux-x64";
      hash = "sha256-S13wxhzJeCI70S9+jVM1VOgLs2CpGSSR3hPaPVOyg6w=";
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
      install -Dm755 "$src" "$out/libexec/omp"
      mkdir -p "$out/bin"
      cat > "$out/bin/omp" <<EOF
      #!${pkgs.runtimeShell}
      exec "${pkgs.stdenv.cc.bintools.dynamicLinker}" \
        --library-path "${lib.makeLibraryPath [ pkgs.glibc ]}" \
        "$out/libexec/omp" "\$@"
      EOF
      chmod 755 "$out/bin/omp"
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
