{
  description = "Multi-host modular NixOS configuration with shared base";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      mkHost = import ./lib/mkhost.nix { inherit inputs; };
    in
    {
      nixosConfigurations = {
        nixos-desktop = mkHost { hostname = "nixos-desktop"; };
        wsl-work = mkHost { hostname = "wsl-work"; };
        # Add new hosts as one line each, e.g.:
        # laptop = mkHost { hostname = "laptop"; };
      };
    };
}
