# Modular NixOS Desktop Configuration

This is an example configuration showing how to organize desktop environments as swappable modules.

## Directory Structure

```
nixos-config2/
├── flake.nix                  # Flake configuration
├── configuration.nix          # Main system configuration
├── home.nix                   # Main home-manager configuration
├── desktops/
│   ├── niri.nix              # Niri window manager system config
│   ├── cosmic.nix            # COSMIC desktop system config
│   └── home/
│       ├── niri.nix          # Niri home-manager config
│       └── cosmic.nix        # COSMIC home-manager config
└── modules/
    └── (your other modules would go here)
```

## How to Switch Desktop Environments

### 1. In `configuration.nix` (lines 13-15):

**For Niri:**
```nix
./desktops/niri.nix
# ./desktops/cosmic.nix
```

**For COSMIC:**
```nix
# ./desktops/niri.nix
./desktops/cosmic.nix
```

### 2. In `home.nix` (lines 11-13):

**For Niri:**
```nix
./desktops/home/niri.nix
# ./desktops/home/cosmic.nix
```

**For COSMIC:**
```nix
# ./desktops/home/niri.nix
./desktops/home/cosmic.nix
```

## What Each Desktop Module Contains

### System-level (`desktops/niri.nix` or `desktops/cosmic.nix`)
- Desktop environment/window manager enablement
- Display manager configuration
- XDG portal settings
- Desktop-specific system packages
- Required system services

### Home-level (`desktops/home/niri.nix` or `desktops/home/cosmic.nix`)
- User services (notification daemons, status bars, etc.)
- Desktop-specific programs (terminal, launcher, etc.)
- User-level configurations

## Benefits

1. **Clean separation** - All DE-specific config in dedicated modules
2. **Easy switching** - Just comment/uncomment one line in each config
3. **No conflicts** - Each DE has isolated configuration
4. **Maintainable** - Easy to see what belongs to each DE
5. **Reusable** - Share desktop modules across different machines

## To Use This Configuration

1. Copy your `hardware-configuration.nix` to this directory
2. Move your existing modules to the `modules/` directory
3. Update the imports in `configuration.nix` and `home.nix` to include them
4. Update the hostname in `flake.nix` (line 33) to match your system
5. Initialize the flake:
   ```bash
   cd ~/nixos-config2
   git init
   git add .
   ```
6. Rebuild with:
   ```bash
   sudo nixos-rebuild switch --flake ~/nixos-config2#nixos-desktop
   ```
   (Replace `nixos-desktop` with your actual hostname)

## Automatic Updates

This configuration includes automatic weekly updates via the `modules/auto-update.nix` module.

### What It Does

**Weekly Updates:**
- Updates ALL flake inputs (nixpkgs, home-manager, stylix, noctalia, etc.)
- Rebuilds your system with the new versions
- Commits the updated `flake.lock` file
- Runs once a week with a randomized delay (to avoid load spikes)
- Safe to rollback if anything breaks (NixOS keeps old generations)

**Weekly Cleanup:**
- Garbage collects system generations older than 30 days
- Optimizes the nix store to save disk space

### Customizing Update Behavior

**Change update frequency** - Edit `dates` in `modules/auto-update.nix`:
```nix
dates = "daily";      # Every day
dates = "weekly";     # Once a week (default: Sunday)
dates = "Mon 03:00";  # Specific day and time
dates = "monthly";    # Once a month
```

**Update only specific inputs** - If you prefer more control, modify the `flags` section:
```nix
flags = [
  "--update-input" "nixpkgs"          # Update only nixpkgs
  "--update-input" "home-manager"     # Update only home-manager
  "--commit-lock-file"
  "-L"
];
```

**Update everything (default)**:
```nix
flags = [
  "--recreate-lock-file"  # Update ALL inputs
  "--commit-lock-file"
  "-L"
];
```

**Disable automatic updates** - Set `enable = false` in the module or remove it from `configuration.nix`

### Monitoring Updates

```bash
# View the systemd timer status
systemctl status nixos-upgrade.timer

# View the last update log
journalctl -u nixos-upgrade.service

# Manually trigger an update now
sudo systemctl start nixos-upgrade.service

# See when the next update is scheduled
systemctl list-timers nixos-upgrade.timer
```

### Manual Updates

You can still manually update at any time:

```bash
# Update all flake inputs
nix flake update

# Update just nixpkgs
nix flake lock --update-input nixpkgs

# Update home-manager only
nix flake lock --update-input home-manager

# Show what's currently locked
nix flake metadata

# After updating, rebuild
sudo nixos-rebuild switch --flake ~/nixos-config2#nixos-desktop
```

### Flake Lock File

The `flake.lock` file pins all your inputs to specific versions:
- **Reproducibility** - Same package versions every build
- **Stability** - No unexpected changes from upstream
- **Control** - You decide when to update

Always commit `flake.lock` to git along with `flake.nix`.

## Notes

- The system-level config requires sudo to rebuild
- The home-manager config can be rebuilt separately with `home-manager switch`
- Both configs need to be set to the same desktop environment
- Common packages and settings stay in the main config files
