{
  description = "NixOS-WSL workstation configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, nixos-wsl, pi, ... }:
    let
      mkWslSystem = system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pi; };
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix
        ];
      };
    in
    {
      nixosConfigurations = {
        nixos-aarch64 = mkWslSystem "aarch64-linux";
        nixos-x86_64 = mkWslSystem "x86_64-linux";
      };
    };
}
