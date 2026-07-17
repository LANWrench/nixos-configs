{ config, pkgs, ... }:

# SSH client config for the homelab fleet. Aliases mirror the Colmena node
# names in ~/nix-fleet/flake.nix, so `ssh edge01` connects to the same host
# colmena deploys to. All fleet nodes log in as the `deploy` user.
#
# Update this list whenever a node is added/removed/re-IP'd in the fleet flake.

{
  programs.ssh = {
    enable = true;

    settings = {
      # --- LAN nodes (172.30.20.0/24) ---
      edge01 = {
        hostname = "172.30.20.92";
        user = "deploy";
      };
      pod01 = {
        hostname = "172.30.20.105";
        user = "deploy";
      };
      db01 = {
        hostname = "172.30.20.121";
        user = "deploy";
      };
      dns01 = {
        hostname = "172.30.20.125";
        user = "deploy";
      };
      proxy01 = {
        hostname = "172.30.20.114";
        user = "deploy";
      };

      # --- Public VPS nodes ---
      vps01 = {
        hostname = "162.250.191.53";
        user = "deploy";
      };
      vps02 = {
        hostname = "209.209.9.120";
        user = "deploy";
      };
    };
  };
}
