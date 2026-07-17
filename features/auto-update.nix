{ config, pkgs, lib, inputs, ... }:

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
      "--commit-lock-file"
    ]
    # Update every flake input weekly — derived from flake.nix, so new
    # inputs are included automatically (no manual list to keep in sync)
    ++ lib.concatMap (name: [ "--update-input" name ])
      (builtins.filter (n: n != "self") (builtins.attrNames inputs));
    dates = "weekly";
    randomizedDelaySec = "45min";
  };

  # REQUIRED: Allow root to access user-owned git repo for auto-upgrades
  # Git 2.35.2+ requires explicit trust for cross-user repo access
  # Without this, nixos-upgrade.service will fail with ownership errors
  environment.etc."gitconfig".text = ''
    [safe]
        directory = /home/michael/nix-config
    [user]
        name = NixOS Auto-Update
        email = nixos-upgrade@nixos-desktop
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