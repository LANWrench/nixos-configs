{ config, pkgs, ... }:

{
  # Host-specific settings (hostname is set by mkHost in lib/mkhost.nix)
  time.timeZone = "America/Chicago";

  # Firewall ports for host-specific services
  networking.firewall.allowedTCPPorts = [
    53317  # LocalSend
  ];
}
