{ config, lib, pkgs, ... }:

{
  imports = [
    ./copilot.nix
    ./unifi-mcp.nix
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
    pkgs.helix
    pkgs.vim
    pkgs.fish
    pkgs.xdg-utils
    pkgs.wslu
    pkgs.wget
  ];

  environment.sessionVariables.BROWSER = "wslview";

  programs.nix-ld.enable = true;

  programs.fish.enable = true;

  programs.starship.enable = true;

  users.defaultUserShell = pkgs.fish;

  system.stateVersion = "25.11";
}
