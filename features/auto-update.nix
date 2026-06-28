{ config, pkgs, lib, ... }:

{
  # ===== AUTOMATIC SYSTEM UPDATES =====
  # This creates two systemd units:
  #   - nixos-upgrade.service (the actual upgrade)
  #   - nixos-upgrade.timer (weekly schedule)
  #
  # Useful commands:
  #   sudo systemctl start nixos-upgrade.service    # Run upgrade now
  #   systemctl status nixos-upgrade.service        # Check status
  #   journalctl -u nixos-upgrade.service           # View logs
  #   systemctl list-timers | grep nixos-upgrade    # Check schedule

  system.autoUpgrade = {
    enable = true;
    flake = "/home/michael/nix-config";
    flags = [
      "-L" # print build logs
    ];
    dates = "weekly";
    randomizedDelaySec = "45min";
  };

  # REQUIRED: Allow root to access user-owned git repo for auto-upgrades
  # Git 2.35.2+ requires explicit trust for cross-user repo access
  # Without this, nixos-upgrade.service will fail with ownership errors
  environment.etc."gitconfig".text = ''
    [safe]
        directory = /home/michael/nix-config
  '';

  # Automatic garbage collection (runs as nix-gc.service)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Nix store optimization (runs as nix-optimise.service)
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}