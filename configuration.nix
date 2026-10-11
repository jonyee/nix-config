{ config, lib, pkgs, ... }:

{
  imports = [
    ./copilot.nix
    ./oh-my-pi.nix
    ./herdr.nix
    ./pi.nix
  ];
  wsl.enable = true;
  wsl.defaultUser = "nixos";
  wsl.interop.register = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = [
    pkgs.git
    pkgs.worktrunk
    pkgs.lazygit
    pkgs.gh
    pkgs.azure-cli
    pkgs.helix
    pkgs.vim
    pkgs.emacs
    pkgs.fish
    pkgs.xdg-utils
    pkgs.wsl-open
    pkgs.wget
  ];

  environment.sessionVariables.BROWSER = "wsl-open";

  environment.shellAliases.nrs =
    ''sudo nixos-rebuild switch --flake "$HOME/git/nix-config#nixos-${lib.removeSuffix "-linux" pkgs.stdenv.hostPlatform.system}"'';

  programs.nix-ld.enable = true;

  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';

  programs.starship.enable = true;

  users.defaultUserShell = pkgs.fish;

  system.stateVersion = "25.11";
}
