# NixOS Configuration

Multi-host NixOS configuration using flakes with shared base configuration.

## Quick Start

```bash
# Clone this repo
git clone git@github.com:LANWrench/nixos-configs.git ~/nix-config
cd ~/nix-config

# Build for your host
sudo nixos-rebuild switch --flake .#nixos-desktop
```

## Hosts

- **nixos-desktop** - Main desktop with Nvidia GPU, GNOME, gaming setup
- **laptop** - (future) Laptop configuration
- **wsl** - (future) WSL instance

## Structure

```
nix-config/
├── flake.nix                    # Flake entry point
├── base/                        # Shared across all hosts
│   ├── core.nix                 # Core packages, fonts
│   ├── security.nix             # SSH, polkit
│   ├── audio.nix                # PipeWire
│   ├── networking.nix           # NetworkManager
│   └── printing.nix             # CUPS
├── features/                    # Optional system features
│   ├── btrfs-snapshots.nix      # Local /home snapshots
│   ├── backup.nix               # Restic off-site backup
│   ├── auto-update.nix          # Weekly updates
│   ├── virtualization.nix       # VMs (libvirt/QEMU)
│   ├── containers.nix           # Podman/OCI
│   └── gaming.nix               # Gaming programs
├── hosts/                       # Per-host configurations
│   └── nixos-desktop/
│       ├── default.nix          # Host entry point
│       ├── hardware.nix         # Nvidia GPU, BTRFS
│       ├── configuration.nix    # Hostname, timezone
│       └── home.nix             # User packages
├── users/
│   └── michael.nix              # User account definition
├── modules/
│   ├── neovim.nix
│   ├── starship.nix
│   └── services/
│       ├── searxng.nix
│       └── caddy.nix
├── desktops/
│   ├── gnome.nix                # System-level DE config
│   ├── kde.nix
│   ├── niri.nix
│   ├── cosmic.nix
│   └── home/                    # User-level DE config
│       ├── gnome.nix
│       ├── kde.nix
│       ├── niri.nix
│       └── cosmic.nix
└── secrets/                     # agenix encrypted secrets
```

See [STRUCTURE.md](STRUCTURE.md) for detailed documentation.

## Backup Strategy

**Fast Recovery (Local):**
- Snapper hourly snapshots of `/home` only
- No root snapshots (prevents accumulation)
- Access at `/home/.snapshots/`

**Disaster Recovery (Off-site):**
- Restic daily backups
- Currently backs up to `/backup` (configure off-site!)
- See [MIGRATION-BACKUP-CLEANUP.md](MIGRATION-BACKUP-CLEANUP.md)

## Adding a New Host

1. Create host directory:
   ```bash
   mkdir -p hosts/laptop
   ```

2. Copy and customize from `hosts/nixos-desktop/`:
   - `default.nix` - Import base + features you need
   - `hardware.nix` - Hardware-specific config
   - `configuration.nix` - Hostname, timezone
   - `home.nix` - User packages

3. Add to `flake.nix`:
   ```nix
   nixosConfigurations = {
     nixos-desktop = ...;
     laptop = nixpkgs.lib.nixosSystem { ... };
   };
   ```

4. Build:
   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```

## Switching Desktop Environments

Edit `hosts/<hostname>/default.nix`:

```nix
# Change from:
../../desktops/gnome.nix

# To:
../../desktops/kde.nix
```

Also update `hosts/<hostname>/home.nix`:

```nix
# Change from:
../../desktops/home/gnome.nix

# To:
../../desktops/home/kde.nix
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

## Maintenance

### Update System
```bash
# Update flake inputs
nix flake update

# Rebuild
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### Clean Old Generations
```bash
# Delete generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d

# Optimize nix store
nix-store --optimise
```

### Check Backups
```bash
# List snapshots
sudo snapper -c home list

# List restic backups
sudo restic -r /backup snapshots

# Check backup logs
journalctl -u restic-backups-fullMachine.service -n 100
```

## Automatic Updates

Weekly automatic updates are enabled via `features/auto-update.nix`:
- Updates all flake inputs
- Rebuilds system
- Runs weekly with randomized delay
- Check status: `systemctl status nixos-upgrade.timer`

## Documentation

- [STRUCTURE.md](STRUCTURE.md) - Detailed structure documentation
- [MIGRATION-BACKUP-CLEANUP.md](MIGRATION-BACKUP-CLEANUP.md) - Backup strategy details

## License

Personal configuration - feel free to use as reference.
