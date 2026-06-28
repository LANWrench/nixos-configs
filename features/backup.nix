{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    restic
  ];

  # Restic backup - disaster recovery (off-site protection)
  services.restic.backups = {
    fullMachine = {
      # Backup critical paths
      paths = [
        "/home"           # User data (primary focus)
        "/etc/nixos"      # System config if stored here
        # Add other critical paths as needed:
        # "/var/lib"      # System state/databases
        # "/root"         # Root user home
      ];

      # Exclude unnecessary data
      exclude = [
        "/home/*/.cache"
        "/home/*/.local/share/Trash"
        "/home/*/Downloads"
        "/home/*/.snapshots"      # Don't backup the snapshots themselves
        "/home/*/.steam"          # Steam games are huge and redownloadable
        "/home/*/.local/share/Steam"
        "**/.git/objects"         # Git objects can be huge
        "**/node_modules"         # Can be reinstalled
        "**/__pycache__"
        "**/target"               # Rust build artifacts
      ];

      # Backup repository location
      repository = "/backup";
      passwordFile = "/root/restic-password.txt";
      initialize = true;

      # Backup schedule - daily at 2:15 AM with random delay
      timerConfig = {
        OnCalendar = "02:15";
        Persistent = true;
        RandomizedDelaySec = "1h";  # Random 0-60min delay
      };

      # Retention policy
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
