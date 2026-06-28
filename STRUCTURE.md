# NixOS Configuration Structure

This NixOS configuration is designed to support multiple hosts (desktops, laptops, WSL instances) while sharing common base configuration.

## Directory Structure

```
nix-config/
├── flake.nix                    # Main entry point for all hosts
│
├── base/                        # Shared configuration across ALL hosts
│   ├── core.nix                 # Core packages, fonts, nix settings
│   ├── security.nix             # SSH, polkit, FUSE
│   ├── audio.nix                # PipeWire audio stack
│   ├── networking.nix           # NetworkManager
│   └── printing.nix             # CUPS and printer discovery
│
├── hosts/                       # Host-specific configurations
│   └── nixos-desktop/           # Desktop host configuration
│       ├── default.nix          # Main entry point (imports everything)
│       ├── hardware.nix         # Nvidia GPU, boot, BTRFS config
│       ├── configuration.nix    # Hostname, timezone, gaming programs
│       └── home.nix             # User packages and programs for this host
│
├── users/                       # User account definitions
│   └── michael.nix              # User account, groups, shell
│
├── features/                    # Optional system features
│   ├── btrfs-snapshots.nix      # BTRFS snapshots (/home only)
│   ├── backup.nix               # Restic backup service
│   ├── auto-update.nix          # Weekly auto-updates
│   ├── virtualization.nix       # libvirt/QEMU setup
│   ├── containers.nix           # Podman/OCI containers
│   └── gaming.nix               # Gaming programs (gamemode, gamescope)
│
├── modules/                     # Smaller configs & services
│   ├── neovim.nix               # Neovim configuration
│   ├── starship.nix             # Starship prompt
│   └── services/                # Optional services
│       ├── searxng.nix          # SearXNG container
│       └── caddy.nix            # Reverse proxy
│
├── desktops/                    # Desktop environment configs
│   ├── gnome.nix                # GNOME system config
│   ├── kde.nix                  # KDE system config
│   ├── niri.nix                 # Niri system config
│   ├── cosmic.nix               # COSMIC system config
│   └── home/                    # User-level DE configs
│       ├── gnome.nix
│       ├── kde.nix
│       ├── niri.nix
│       └── cosmic.nix
│
├── secrets/                     # agenix encrypted secrets
│   ├── searxng-settings.age
│   └── caddy-env.age
│
├── hardware-configuration.nix   # Generated hardware config
├── configuration.nix            # DEPRECATED (kept as reference)
└── home.nix                     # DEPRECATED (kept as reference)
```

## How to Add a New Host

### Example: Adding a laptop configuration

1. **Create host directory**:
   ```bash
   mkdir -p hosts/laptop
   ```

2. **Create `hosts/laptop/default.nix`**:
   ```nix
   { config, lib, pkgs, inputs, ... }:

   {
     imports = [
       # Base configuration (shared)
       ../../base/core.nix
       ../../base/security.nix
       ../../base/audio.nix
       ../../base/networking.nix
       ../../base/printing.nix

       # User configuration
       ../../users/michael.nix

       # Hardware configuration
       ../../hardware-configuration.nix
       ./hardware.nix

       # Host-specific configuration
       ./configuration.nix

       # Choose which modules you need
       ../../modules/snapper.nix
       ../../modules/restic.nix

       # Desktop Environment
       ../../desktops/kde.nix  # Or gnome, niri, cosmic
     ];

     system.stateVersion = "25.05";
   }
   ```

3. **Create `hosts/laptop/hardware.nix`**:
   - Add laptop-specific hardware config (AMD GPU, power management, etc.)

4. **Create `hosts/laptop/configuration.nix`**:
   ```nix
   { config, pkgs, ... }:

   {
     networking.hostName = "laptop";
     time.timeZone = "America/Chicago";

     # Laptop-specific settings
     services.tlp.enable = true;  # Battery optimization
     # Add other laptop-specific config
   }
   ```

5. **Create `hosts/laptop/home.nix`**:
   - Copy from nixos-desktop/home.nix and customize packages

6. **Update `flake.nix`**:
   ```nix
   nixosConfigurations = {
     nixos-desktop = nixpkgs.lib.nixosSystem { ... };

     laptop = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       specialArgs = {
         inherit inputs;
         pkgs-stable = import inputs.nixpkgs-stable {
           system = "x86_64-linux";
           config.allowUnfree = true;
         };
       };
       modules = [
         { nixpkgs.config.allowUnfree = true; }
         ./hosts/laptop

         agenix.nixosModules.default

         home-manager.nixosModules.home-manager
         {
           home-manager.backupFileExtension = "backup";
           home-manager.useGlobalPkgs = true;
           home-manager.useUserPackages = true;
           home-manager.extraSpecialArgs = {
             pkgs-stable = import inputs.nixpkgs-stable {
               system = "x86_64-linux";
               config.allowUnfree = true;
             };
           };
           home-manager.users.michael = {
             imports = [
               ./hosts/laptop/home.nix
               stylix.homeModules.stylix
             ];
           };
         }
       ];
     };
   }
   ```

7. **Build the new host**:
   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```

## Configuration Guidelines

### What Goes in `base/`?
- Configuration shared by **ALL** hosts
- Core system packages (vim, git, curl)
- Common services (SSH, audio, printing)
- Universal settings that every system needs

### What Goes in `hosts/<hostname>/`?
- Host-specific settings (hostname, timezone)
- Hardware configuration (GPU, CPU optimizations)
- Desktop environment choice
- Host-specific packages and services
- Firewall rules specific to that host

### What Goes in `users/`?
- User account definitions
- User groups
- Shell configuration
- Settings that follow the user across hosts

### What Goes in `features/`?
- Big optional system features (VMs, containers, gaming, backups)
- Features that significantly impact the system
- Features that hosts may or may not want

### What Goes in `modules/`?
- Smaller user-level configurations (neovim, starship)
- Optional services (searxng, caddy)
- Development tool configurations

## Switching Desktop Environments

To change desktop environments for a host, edit `hosts/<hostname>/default.nix`:

```nix
# Change from:
../../desktops/gnome.nix

# To:
../../desktops/kde.nix
```

Also update the home configuration in `hosts/<hostname>/home.nix`:

```nix
# Change from:
../../desktops/home/gnome.nix

# To:
../../desktops/home/kde.nix
```

## WSL Support

For WSL instances, create `hosts/wsl/` with:
- No desktop environment imports
- WSL-specific kernel and systemd settings
- Lightweight package selection
- Windows interop configuration

## Maintenance

### Updating the system
```bash
# Update flake inputs
nix flake update

# Rebuild
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### Cleaning old generations
```bash
# Delete old generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d
```

### Testing changes
```bash
# Test without activating
sudo nixos-rebuild test --flake .#nixos-desktop

# Build and test but don't set as boot default
sudo nixos-rebuild test --flake .#nixos-desktop
```

## Benefits of This Structure

1. **Shared Base**: Common configuration in one place
2. **Easy Multi-Host**: Add new hosts by creating a new directory
3. **No Duplication**: Reusable modules prevent copy-paste
4. **Clear Separation**: Host-specific vs shared is obvious
5. **Easy Desktop Switching**: Change DE by updating imports
6. **Maintainable**: Each file has a single, clear purpose
