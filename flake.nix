{
  description = "Modular NixOS Desktop Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Older nixpkgs for broken packages
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-24.11";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, stylix, noctalia, ... }: {
    nixosConfigurations = {
      # Replace "nixos-desktop" with your actual hostname
      nixos-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          pkgs-stable = import inputs.nixpkgs-stable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        modules = [
          { nixpkgs.config.allowUnfree = true; }
          ./configuration.nix

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
                noctalia.homeModules.default
              ];
            };
          }
        ];
      };
    };
  };
}
