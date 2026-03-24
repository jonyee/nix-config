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
    pkgs.gh
    pkgs.helix
    pkgs.fish
    pkgs.fishPlugins.bobthefish
  ];

  programs.fish.enable = true;

  users.defaultUserShell = pkgs.fish;

  system.stateVersion = "25.11";
}
