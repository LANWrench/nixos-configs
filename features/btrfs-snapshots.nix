{ config, pkgs, ... }:

{
  # Install snapper tools
  environment.systemPackages = with pkgs; [
    snapper
    snapper-gui  # Optional: GUI for browsing snapshots
  ];

  # ============ BTRFS SNAPSHOTS WITH SNAPPER ============
  # NOTE: NixOS won't automatically create .snapshots subvolumes
  # Create manually: sudo btrfs subvolume create /home/.snapshots

  services.snapper = {
    # Snapshot configuration for /home only
    configs = {
      home = {
        SUBVOLUME = "/home";

        # Automatic timeline snapshots
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;

        # Retention policy - keep snapshots for:
        TIMELINE_MIN_AGE = "1800";      # Keep all snapshots for 30 minutes
        TIMELINE_LIMIT_HOURLY = "5";    # Keep 5 hourly snapshots (last 5 hours)
        TIMELINE_LIMIT_DAILY = "7";     # Keep 7 daily snapshots (last week)
        TIMELINE_LIMIT_WEEKLY = "4";    # Keep 4 weekly snapshots (last month)
        TIMELINE_LIMIT_MONTHLY = "6";   # Keep 6 monthly snapshots (last 6 months)

        # Space management
        SPACE_LIMIT = "0.2";  # Use max 20% of disk for snapshots
        FREE_LIMIT = "0.15";  # Keep at least 15% free space

        # Allow users to browse their own snapshots
        ALLOW_USERS = [ "michael" ];
        ALLOW_GROUPS = [ "wheel" ];
      };
    };

    # DISABLED: Don't create snapshots on every boot
    # Timeline snapshots (hourly) are sufficient
    snapshotRootOnBoot = false;
  };
}
