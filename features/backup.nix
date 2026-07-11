{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    restic
  ];

  age.secrets."b2-handmcnet-backups-s3".file = ../secrets/b2-handmcnet-backups-s3.age;

  # Restic backup - disaster recovery (off-site protection)
  services.restic.backups = {
    fullMachine = {

      # Backup critical paths
      paths = [
        "/home" # User data (primary focus)
        "/etc/nixos" # System config if stored here
        # Add other critical paths as needed:
        # "/var/lib"      # System state/databases
        # "/root"         # Root user home
      ];

      # Exclude unnecessary data
      exclude = [
        "/home/*/.cache"
        "/home/*/.local/share/Trash"
        "/home/*/Downloads"
        "/home/.snapshots" # Snapper/btrfs snapshots of /home (N full copies!) — NOT per-user
        "/home/*/.snapshots" # Any per-user snapshot dirs, just in case
        "/home/*/.steam" # Steam games are huge and redownloadable
        "/home/*/.local/share/Steam"
        "/home/*/.lmstudio/models" # Can always redownload models, they are big

        "**/.git/objects" # Git objects can be huge
        "**/node_modules" # Can be reinstalled
        "**/__pycache__"
        "**/target" # Rust build artifacts

      ];

      environmentFile = config.age.secrets."b2-handmcnet-backups-s3".path;

      passwordFile = "/root/restic-password.txt";

      initialize = true;
      repository = "s3:s3.us-east-005.backblazeb2.com/handmcnet-backups/${config.networking.hostName}";

      # Backup schedule - daily at 2:15 AM with random delay
      timerConfig = {
        OnCalendar = "02:15";
        Persistent = true;
        RandomizedDelaySec = "1h"; # Random 0-60min delay
      };

      # Off-site retention. Snapper covers fine-grained recent history locally
      # (see features/btrfs-snapshots.nix), so restic is disaster recovery only.
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];

      # Repository maintenance
      checkOpts = [
        "--with-cache"
      ];
    };
  };
}
