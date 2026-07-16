{ config, pkgs, ... }:

{
  # Host-specific settings (hostname is set by mkHost in lib/mkhost.nix).
  time.timeZone = "America/Chicago";

  # No password needed: NixOS-WSL sets security.sudo.wheelNeedsPassword = false,
  # and WSL logs in without authentication. Run `passwd` to set one if desired.

  # No firewall ports opened by default; WSL shares the Windows network stack.
  # networking.firewall.allowedTCPPorts = [ ];
}
