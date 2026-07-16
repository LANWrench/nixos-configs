# Builds a nixosSystem with home-manager, agenix, and pkgs-stable pre-wired.
# Each host in flake.nix is one line:  <name> = mkHost { hostname = "<name>"; };
#
# Expects hosts/<hostname>/default.nix (system) and hosts/<hostname>/home.nix
# (home-manager) to exist.
{ inputs }:
{ hostname, system ? "x86_64-linux", user ? "michael", extraModules ? [ ] }:
let
  pkgs-stable = import inputs.nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs pkgs-stable; };
  modules = [
    {
      nixpkgs.config.allowUnfree = true;
      networking.hostName = hostname;
    }
    ../hosts/${hostname}

    inputs.agenix.nixosModules.default

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        backupFileExtension = "backup";
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs pkgs-stable; };
        users.${user}.imports = [
          ../hosts/${hostname}/home.nix
          inputs.stylix.homeModules.stylix
        ];
      };
    }
  ] ++ extraModules;
}
