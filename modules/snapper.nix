{ config, pkgs, ... }:

{
  # Install snapper tools
  environment.systemPackages = with pkgs; [
    snapper
    snapper-gui  # Optional: GUI for browsing snapshots
  ];

  # ============ BTRFS SNAPSHOTS WITH SNAPPER ============
  # NOTE: Apparently NixOS configuration won't automatically create the necessary subvolumes for ".snapshots" for each parent subvolume. Make sure these are created (i.e. /home/.snapshots, /.snapshots
  services.snapper = {
    configs = {
      # Snapshot configuration for root
      root = {
        SUBVOLUME = "/";
        
        # Snapshot schedule
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        
        # Keep snapshots for:
        TIMELINE_MIN_AGE = "3600";      # Keep all snapshots for 1 hour
        TIMELINE_LIMIT_HOURLY = "5";    # Keep 5 hourly snapshots
        TIMELINE_LIMIT_DAILY = "7";     # Keep 7 daily snapshots
        TIMELINE_LIMIT_WEEKLY = "4";    # Keep 4 weekly snapshots
        TIMELINE_LIMIT_MONTHLY = "12";  # Keep 12 monthly snapshots
        TIMELINE_LIMIT_YEARLY = "3";    # Keep 3 yearly snapshots
        
        # Space management
        SPACE_LIMIT = "0.5";  # Use max 50% of disk for snapshots
        FREE_LIMIT = "0.2";   # Keep at least 20% free space
        
        # Allow users to see snapshots
#        ALLOW_USERS = [ "michael" ];
        ALLOW_GROUPS = [ "wheel" ];
      };
      
      # Optional: Separate config for /home if on different subvolume
      home = {
        SUBVOLUME = "/home";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = "3";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "2";
        TIMELINE_LIMIT_MONTHLY = "6";
        ALLOW_USERS = [ "michael" ];
      };
    };
    
    # Automatically create snapshots before nixos-rebuild
    snapshotRootOnBoot = true;
  };
}
