{ pkgs, pi, ... }:

let
  extensions = pkgs.buildNpmPackage {
    pname = "pi-extensions";
    version = "1.0.0";
    src = ./pi-extensions;

    npmDepsHash = "sha256-ebsuL3MWvNatR8uA28UkrWb0o57HcSTX7V40OOEGxOo=";
    # Pi provides its own host libraries; do not install duplicate peers.
    npmFlags = [ "--legacy-peer-deps" "--ignore-scripts" ];
    npmInstallFlags = [ "--ignore-scripts" ];
    dontNpmBuild = true;

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r node_modules package.json "$out/"
      runHook postInstall
    '';

    meta.platforms = [ "aarch64-linux" "x86_64-linux" ];
  };
in
{
  imports = [ pi.nixosModules.default ];

  programs.pi.coding-agent = {
    enable = true;
    extensions = [
      "${extensions}/node_modules/pi-mcp-adapter"
      "${extensions}/node_modules/pi-powerline-footer"
      "${extensions}/node_modules/pi-web-access"
    ];
  };
}
