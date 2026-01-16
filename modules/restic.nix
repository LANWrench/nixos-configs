{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    restic
  ];

  # Single backup service - full machine
  services.restic.backups = {
    fullMachine = {
      
      # Everything important, my config is only backing up the latest snapshot so I am not trying to backup live data
     # paths = [
     #  # # Get latest snapshot for root (snapshots are stored in /.snapshots)
     #  # "/.snapshots/$(ls -v /.snapshots | tail -1)/snapshot"
     #  # # Get latest snapshot for /home
     #  # "/home/.snapshots/$(ls -v /home/.snapshots | tail -1)/snapshot"
     # ];

      dynamicFilesFrom = ''
        latest_root=$(ls -v /.snapshots | tail -1)
        latest_home=$(ls -v /home/.snapshots | tail -1)
        echo "/.snapshots/$latest_root/snapshot"
        echo "/home/.snapshots/$latest_home/snapshot"
      '';

      passwordFile = "/root/restic-password.txt";
      
      # Rclone config
      # rcloneConfigFile = "/root/.config/rclone/rclone.conf";
      initialize = true;
      repository = "/backup";

      # Backup schedule - daily at 2am
      timerConfig = {
        OnCalendar = "02:15";

        Persistent = true;
        RandomizedDelaySec = "1h";  # Random 0-60min delay
      };
      
      # Keep backups for
      pruneOpts = [
        "--keep-daily 7"      # Last 7 days
        "--keep-weekly 4"     # Last 4 weeks
        "--keep-monthly 6"    # Last 6 months
        "--keep-yearly 2"     # Last 2 years
      ];
      
      # Repository maintenance
      checkOpts = [
        "--with-cache"
      ];
    };
  };
}
