# Backup Configuration Migration & Cleanup Guide

## What Changed

Your backup configuration has been simplified and reorganized:

### Old Structure (DEPRECATED)
```
modules/
├── snapper.nix        # Root + /home snapshots, boot snapshots enabled
├── restic.nix         # Backed up from snapshots
├── auto-update.nix
├── virtualization.nix
└── containers.nix
```

### New Structure (ACTIVE)
```
features/                        # Optional system features
├── btrfs-snapshots.nix         # /home ONLY, no boot snapshots
├── backup.nix                  # Restic: live /home backup
├── gaming.nix                  # gamemode + gamescope
├── auto-update.nix             # Weekly updates
├── virtualization.nix          # VMs
└── containers.nix              # Podman/OCI

modules/
├── neovim.nix                  # User configs
├── starship.nix
└── services/                   # Optional services
    ├── searxng.nix
    └── caddy.nix
```

## New Backup Strategy

**Tier 1: Fast Local Recovery (Minutes)**
- Snapper snapshots of `/home` only
- Hourly snapshots (5 hours), daily (7 days), weekly (4 weeks), monthly (6 months)
- For "oops I deleted a file" scenarios
- Access at: `/home/.snapshots/`

**Tier 2: Disaster Recovery (Hours)**
- Restic backup to `/backup` (or change to off-site location)
- Daily backups of `/home` (with exclusions for cache, trash, etc.)
- For disk failure, ransomware, hardware loss
- Restore with: `restic restore`

**Removed:**
- ❌ Root (`/`) snapshots (caused accumulation, 277 snapshots!)
- ❌ Boot snapshots (created on every boot, not cleaned up properly)
- ❌ Backup from snapshots (simplified to live filesystem backup)

## Required Manual Steps

### Step 1: Test the New Configuration

```bash
# Build the new configuration (don't activate yet)
cd ~/nix-config
sudo nixos-rebuild build --flake .#nixos-desktop

# If successful, switch to it
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### Step 2: Clean Up Old Root Snapshots (IMPORTANT!)

You currently have **277 root snapshots** that are wasting disk space. Clean them up:

```bash
# List all root snapshots
sudo snapper -c root list

# Option A: Delete all old snapshots (keep only latest)
# WARNING: This will delete all but the most recent snapshot
sudo snapper -c root delete 1-5737

# Option B: Delete in batches (safer)
sudo snapper -c root delete 1-1000
sudo snapper -c root delete 1001-2000
sudo snapper -c root delete 2001-3000
sudo snapper -c root delete 3001-4000
sudo snapper -c root delete 4001-5000
sudo snapper -c root delete 5001-5737

# After cleanup, verify
sudo snapper -c root list
# Should show very few snapshots (or none if you deleted them all)
```

### Step 3: Verify New Snapper Configuration

```bash
# Check that only home snapshots are being created
sudo snapper list-configs
# Should show: home (not root)

# Wait an hour and verify new snapshots are being created
sudo snapper -c home list
# Should show hourly snapshots starting to appear

# Check the timeline service
systemctl status snapper-timeline.timer
systemctl status snapper-cleanup.timer
```

### Step 4: Verify Restic Backup

```bash
# Check next backup time
systemctl list-timers | grep restic

# Check recent backup logs
journalctl -u restic-backups-fullMachine.service -n 100

# After next backup runs, verify it worked
sudo restic -r /backup snapshots
# Should show new snapshots being created

# Test a restore (safe, just lists files)
sudo restic -r /backup ls latest
```

### Step 5: Configure Off-Site Backup (RECOMMENDED)

Currently Restic backs up to `/backup` on the same disk. This doesn't protect against:
- Disk failure
- Fire/theft
- Ransomware

**Option A: Backup to External Drive**
```nix
# In features/backup.nix, change:
repository = "/backup";
# To:
repository = "/mnt/external-drive/backups";
```

**Option B: Backup to Cloud (Recommended)**
```nix
# In features/backup.nix:
repository = "b2:bucket-name:path";  # Backblaze B2
# OR
repository = "s3:s3.amazonaws.com/bucket-name";  # AWS S3
# OR
repository = "rest:https://backup-server.com/repo";  # Any REST server

# Add rclone config file:
rcloneConfigFile = "/root/.config/rclone/rclone.conf";
```

### Step 6: Clean Up Old Files (Optional)

After confirming everything works for a few days:

```bash
cd ~/nix-config

# Delete deprecated files
rm modules/snapper.nix
rm modules/restic.nix

# Delete old configuration.nix and home.nix if not needed as reference
rm configuration.nix
rm home.nix
```

## Monitoring Your Backups

### Check Snapshot Status
```bash
# List /home snapshots
sudo snapper -c home list

# See disk usage of snapshots
du -sh /home/.snapshots

# Browse a snapshot
ls /home/.snapshots/123/snapshot/michael/
```

### Check Restic Status
```bash
# List all backup snapshots
sudo restic -r /backup snapshots

# Check repository stats
sudo restic -r /backup stats

# Verify repository integrity
sudo restic -r /backup check
```

### Restore Examples

**From Snapper (fast, local):**
```bash
# Restore a single file
sudo cp /home/.snapshots/123/snapshot/michael/Documents/important.txt ~/Documents/

# Or use snapper's undo
sudo snapper -c home undochange 120..125
```

**From Restic (slower, complete):**
```bash
# List available snapshots
sudo restic -r /backup snapshots

# Restore entire /home
sudo restic -r /backup restore latest --target /mnt/restore

# Restore specific file
sudo restic -r /backup restore latest --target /tmp/restore --include /home/michael/Documents/important.txt
```

## Troubleshooting

### Snapper Timeline Not Creating Snapshots
```bash
# Check timer status
systemctl status snapper-timeline.timer

# Check for errors
journalctl -u snapper-timeline.service -n 50

# Manually trigger
sudo systemctl start snapper-timeline.service
```

### Restic Backup Failing
```bash
# Check logs
journalctl -u restic-backups-fullMachine.service -n 100

# Common issues:
# - Password file missing: ensure /root/restic-password.txt exists
# - Repository not initialized: sudo restic -r /backup init
# - Permissions: ensure root can access backup paths
```

### Disk Space Issues
```bash
# Check snapshot space usage
sudo btrfs filesystem df /
sudo btrfs filesystem usage /

# Clean up old snapshots manually
sudo snapper -c home delete <range>

# Clean up old Restic snapshots
sudo restic -r /backup forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
```

## Expected Disk Usage

With the new configuration:

- **Snapper /home**: ~5-20% of /home size (depends on change rate)
- **Restic**: Initial backup ~= /home size, incremental backups are smaller due to deduplication
- **Root snapshots**: 0 (disabled)

## Benefits of New Strategy

✅ **Simpler**: Only one snapshot config, clearer backup purpose
✅ **No accumulation**: Boot snapshots disabled, proper cleanup limits
✅ **Fast recovery**: Snapper for quick file restores
✅ **Disaster recovery**: Restic for complete system restore
✅ **Less disk waste**: No redundant root snapshots
✅ **Easier to understand**: Clear separation of concerns

## Questions?

- **Q: What if I break my system config?**
  A: Your config is in Git and in Restic backups. Restore from either.

- **Q: Can I still rollback NixOS generations?**
  A: Yes! That's unchanged. This only affects BTRFS snapshots.

- **Q: What if my disk dies?**
  A: Boot from NixOS USB, restore `/home` from Restic, rebuild system from your config.

- **Q: Should I keep root snapshots?**
  A: No. Your NixOS config is declarative and in Git. Root is reproducible.

- **Q: What about /var or /etc?**
  A: Add them to `features/backup.nix` paths if you have important state there.
