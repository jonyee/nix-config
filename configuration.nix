{ config, lib, pkgs, pi, ... }:

{
  imports = [
    ./copilot.nix
    ./oh-my-pi.nix
  ];
  wsl.enable = true;
  wsl.defaultUser = "nixos";
  wsl.interop.register = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.permittedInsecurePackages = [
    "jujutsu-0.23.0"
  ];

  environment.systemPackages = [
    pkgs.git
    pkgs.jujutsu
    pkgs.lazyjj
    pkgs.lazygit
    pkgs.gh
    pkgs.azure-cli
    pkgs.helix
    pkgs.vim
    pkgs.fish
    pkgs.xdg-utils
    pkgs.wslu
    pkgs.wget
    pi.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent
  ];

  environment.sessionVariables.BROWSER = "wslview";

  programs.nix-ld.enable = true;

  programs.fish.enable = true;

  programs.starship.enable = true;

  users.defaultUserShell = pkgs.fish;

  system.stateVersion = "25.11";
}
