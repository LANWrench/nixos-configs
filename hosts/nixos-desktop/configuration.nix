{ config, pkgs, ... }:

{
  # Host-specific settings
  networking.hostName = "nixos-desktop";
  time.timeZone = "America/Chicago";

  # Firewall ports for host-specific services
  networking.firewall.allowedTCPPorts = [
    53317  # LocalSend
  ];
}
