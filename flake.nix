{
  description = "Modular NixOS Desktop Configuration";

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
      # Replace "nixos-desktop" with your actual hostname
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
          ./configuration.nix

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
                ./home.nix
                stylix.homeModules.stylix
              ];
            };
          }
        ];
      };
    };
  };
}
