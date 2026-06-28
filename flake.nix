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
  };

  outputs = inputs@{ nixpkgs, home-manager, stylix, agenix, ... }: {
    nixosConfigurations = {
      # Desktop host configuration
      # Add new hosts here (laptop, wsl, etc.) with their own host directories
      nixos-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          pkgs-stable = import inputs.nixpkgs-stable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        modules = [
          { nixpkgs.config.allowUnfree = true; }
          ./hosts/nixos-desktop

          agenix.nixosModules.default

          # Integrate home-manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              pkgs-stable = import inputs.nixpkgs-stable {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
            };
            home-manager.users.michael = {
              imports = [
                ./hosts/nixos-desktop/home.nix
                stylix.homeModules.stylix
              ];
            };
          }
        ];
      };
    };
  };
}
