# Setting Up a New NixOS Host

This guide walks through deploying this configuration to a fresh NixOS installation.

## Prerequisites

- Fresh NixOS installation (basic system working)
- Internet connection
- Root access or sudo privileges

## Quick Start (Same User/Setup)

If the new machine is similar to your existing setup:

```bash
# 1. Clone this repo
git clone https://github.com/LANWrench/nixos-configs.git ~/nix-config
cd ~/nix-config

# 2. Copy hardware config
sudo cp /etc/nixos/hardware-configuration.nix ~/nix-config/

# 3. Create new host (or use nixos-desktop if similar)
# Skip this if using existing host config

# 4. Update flake.nix with hostname if needed

# 5. Build
sudo nixos-rebuild switch --flake ~/nix-config#nixos-desktop
```

## Detailed Setup for New Host

### Step 1: Install Base NixOS System

1. Boot from NixOS installer
2. Partition disk (recommend BTRFS for snapshots)
3. Mount partitions
4. Generate base config:
   ```bash
   nixos-generate-config --root /mnt
   ```
5. Install:
   ```bash
   nixos-install
   reboot
   ```

### Step 2: Initial Boot Setup

After rebooting into fresh system:

```bash
# Ensure git is available (should be in base system)
# If not:
nix-shell -p git

# Set up SSH keys for GitHub (if using SSH clone)
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add this key to GitHub: Settings → SSH and GPG keys
```

### Step 3: Clone Configuration

```bash
# SSH (if you set up keys)
git clone git@github.com:LANWrench/nixos-configs.git ~/nix-config

# OR HTTPS (easier for first setup)
git clone https://github.com/LANWrench/nixos-configs.git ~/nix-config

cd ~/nix-config
```

### Step 4: Create Host Configuration

#### Option A: Use Existing Host (Desktop → Desktop)

If the new machine is similar to nixos-desktop:

```bash
# Just copy the hardware config
sudo cp /etc/nixos/hardware-configuration.nix ~/nix-config/

# Edit hostname in hosts/nixos-desktop/configuration.nix
nano hosts/nixos-desktop/configuration.nix
# Change: networking.hostName = "nixos-desktop"; → your new hostname
```

#### Option B: Create New Host (e.g., Laptop)

```bash
# Create new host directory
mkdir -p hosts/laptop

# Copy desktop as template
cp -r hosts/nixos-desktop/* hosts/laptop/

# Copy hardware config from fresh install
sudo cp /etc/nixos/hardware-configuration.nix hosts/laptop/

# Edit host-specific settings
nano hosts/laptop/configuration.nix
```

**hosts/laptop/configuration.nix:**
```nix
{ config, pkgs, ... }:

{
  # Host-specific settings
  networking.hostName = "laptop";  # ← Change this
  time.timeZone = "America/Chicago";  # ← Adjust if needed

  # Firewall ports for host-specific services
  networking.firewall.allowedTCPPorts = [
    # Add ports as needed
  ];
}
```

**Edit hosts/laptop/default.nix** - Choose features:
```nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Base (always import these)
    ../../base/core.nix
    ../../base/security.nix
    ../../base/audio.nix
    ../../base/networking.nix
    ../../base/printing.nix

    # User
    ../../users/michael.nix

    # Hardware
    ../../hardware-configuration.nix
    ./hardware.nix
    ./configuration.nix

    # Features (pick what you need)
    ../../features/btrfs-snapshots.nix  # ✓ Snapshots
    ../../features/backup.nix           # ✓ Backups
    ../../features/auto-update.nix      # ✓ Auto-updates
    # ../../features/virtualization.nix  # ✗ Skip - too heavy for laptop
    # ../../features/containers.nix      # ✗ Skip if not needed
    # ../../features/gaming.nix          # ✗ Skip - desktop only

    # Desktop environment
    ../../desktops/kde.nix  # Or gnome, niri, cosmic
  ];

  system.stateVersion = "25.05";  # Match your NixOS version
}
```

**Edit hosts/laptop/hardware.nix** - Adjust for laptop hardware:
```nix
{ config, pkgs, ... }:

{
  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    # Remove Nvidia kernel params if using AMD/Intel graphics
  };

  # Graphics (adjust for your GPU)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # LAPTOP SPECIFIC: Power management
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # BTRFS auto-scrub (if using BTRFS)
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };
}
```

**Edit hosts/laptop/home.nix** - Customize packages:
```nix
# Copy from hosts/nixos-desktop/home.nix
# Remove heavy gaming packages, adjust for laptop use
```

### Step 5: Update flake.nix (If Adding New Host)

```bash
nano flake.nix
```

Add new host configuration:

```nix
nixosConfigurations = {
  nixos-desktop = nixpkgs.lib.nixosSystem {
    # ... existing ...
  };

  # ADD THIS:
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
      ./hosts/laptop  # ← Points to your new host

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
};
```

### Step 6: Handle Secrets (If Using)

If you use agenix secrets (searxng, caddy):

```bash
# Copy your age key to new machine
# On old machine:
sudo cat /path/to/age.key

# On new machine:
sudo mkdir -p /etc/agenix
sudo nano /etc/agenix/age.key
# Paste the key
sudo chmod 600 /etc/agenix/age.key
```

**OR skip services that need secrets** by commenting them out in `hosts/<hostname>/default.nix`:
```nix
# ../../modules/services/searxng.nix  # Skip if no secrets
```

### Step 7: Build and Switch

```bash
cd ~/nix-config

# Test build first (doesn't activate)
sudo nixos-rebuild build --flake .#laptop

# If successful, switch
sudo nixos-rebuild switch --flake .#laptop
```

### Step 8: Post-Install Setup

```bash
# If using BTRFS snapshots, create snapshot subvolume
sudo btrfs subvolume create /home/.snapshots

# Set up Restic password
sudo nano /root/restic-password.txt
# Add a strong password
sudo chmod 600 /root/restic-password.txt

# Initialize Restic repository
sudo restic -r /backup init
# OR for off-site: sudo restic -r /mnt/external/backup init

# Reboot to ensure everything works
sudo reboot
```

## Special Cases

### WSL Instance

For Windows Subsystem for Linux:

```bash
# Create minimal WSL host
mkdir -p hosts/wsl

# Skip these features:
# - btrfs-snapshots (WSL doesn't use BTRFS)
# - backup (or configure differently)
# - virtualization (can't run VMs in WSL)
# - gaming
# - No desktop environment
```

Example `hosts/wsl/default.nix`:
```nix
{
  imports = [
    ../../base/core.nix
    ../../base/security.nix
    ../../users/michael.nix
    ./configuration.nix

    # Containers work in WSL
    ../../features/containers.nix
  ];
}
```

### Different User

If setting up for a different user:

```bash
# Create new user config
cp users/michael.nix users/yourname.nix

# Edit:
nano users/yourname.nix
```

```nix
{ config, pkgs, ... }:

{
  users.users.yourname = {  # ← Change username
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "cdrom" "libvirtd" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
}
```

Update imports in host config and flake.nix to use new user.

## Troubleshooting

### Build Fails: "path does not exist"
- Check all import paths in your host's `default.nix`
- Ensure you copied `hardware-configuration.nix`

### Build Fails: "option does not exist"
- Comment out features you don't need
- Check for hardware-specific options (Nvidia on AMD laptop)

### Secrets Error
- Comment out services that need secrets
- Or copy age keys from existing system

### Git Tree is Dirty
- Commit your changes: `git add . && git commit -m "Add laptop host"`
- Or use `--impure` flag (not recommended)

## Verification Checklist

After successful rebuild:

- [ ] System boots
- [ ] Desktop environment works
- [ ] Network connection works
- [ ] Audio works
- [ ] User can login
- [ ] SSH works (if configured)
- [ ] Timers are running: `systemctl list-timers`
- [ ] Snapshots created (if using): `sudo snapper list-configs`

## Next Steps

1. **Commit your new host config**:
   ```bash
   git add .
   git commit -m "Add laptop host configuration"
   git push
   ```

2. **Configure off-site backups** - Edit `features/backup.nix` to use external storage or cloud

3. **Customize packages** - Edit `hosts/<hostname>/home.nix` for host-specific needs

4. **Test restore** - Verify you can restore from snapshots/backups

## Quick Reference

```bash
# Build without activating
sudo nixos-rebuild build --flake .#hostname

# Test (activates but doesn't set as boot default)
sudo nixos-rebuild test --flake .#hostname

# Switch (activate and set as boot default)
sudo nixos-rebuild switch --flake .#hostname

# Rollback if something breaks
sudo nixos-rebuild switch --rollback

# Update flake inputs
nix flake update

# Clean old generations
sudo nix-collect-garbage --delete-older-than 30d
```
