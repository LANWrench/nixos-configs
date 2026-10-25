# Builds a nixosSystem with home-manager, agenix, and pkgs-stable pre-wired.
# Each host in flake.nix is one line:  <name> = mkHost { hostname = "<name>"; };
#
# Expects hosts/<hostname>/default.nix to exist. It is the machine's full
# recipe — system AND home-manager config both come from the modules it
# imports (they set home-manager.users.michael directly).
{ inputs }:
{ hostname, system ? "x86_64-linux", extraModules ? [ ] }:
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
        # Home-manager modules every host's user config can use. (Stylix is
        # NOT here: desktops/niri.nix imports it, so hosts without a desktop
        # never load it.)
        sharedModules = [
          inputs.agenix.homeManagerModules.default
        ];
      };
    }
  ] ++ extraModules;
}
