{ config, lib, pkgs, ... }:

{
  imports = [
    <nixos-wsl/modules>
    ./copilot.nix
  ];
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  environment.systemPackages = [
    pkgs.git
    pkgs.jujutsu
    pkgs.gh
    pkgs.helix
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
