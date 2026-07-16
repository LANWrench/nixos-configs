# Setting Up a New NixOS Host

This guide walks through deploying this configuration to a fresh NixOS installation.

## Prerequisites

- Fresh NixOS installation (basic system working)
- Internet connection
- Root access or sudo privileges

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/LANWrench/nixos-configs.git ~/nix-config
cd ~/nix-config

# 2. Create the host from the checklist below (host dir + one flake line)

# 3. Build
git add .   # flakes only see git-tracked files
sudo nixos-rebuild switch --flake ~/nix-config#<hostname>
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

After rebooting into the fresh system:

```bash
# Ensure git is available. If not:
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

### Step 4: Create the Host Directory

```bash
mkdir -p hosts/laptop

# Copy the GENERATED hardware config from the fresh install — this is
# per-host and never shared between machines
sudo cp /etc/nixos/hardware-configuration.nix hosts/laptop/
```

**hosts/laptop/default.nix** — the machine's full recipe:

```nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Universal base (always — WSL-safe by construction)
    ../../base

    # Physical machine profile: audio, NetworkManager, printing, fonts
    # (skip on WSL)
    ../../profiles/physical.nix

    # User
    ../../users/michael.nix

    # Hardware
    ./hardware-configuration.nix   # generated — never hand-edit
    ./hardware.nix                 # hand-written: GPU, boot, filesystems
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

  system.stateVersion = "25.05";  # The release this machine was INSTALLED with
}
```

**hosts/laptop/configuration.nix** — hostname is set automatically by `mkHost`:

```nix
{ config, pkgs, ... }:

{
  time.timeZone = "America/Chicago";

  # Firewall ports for host-specific services
  networking.firewall.allowedTCPPorts = [
    # Add ports as needed
  ];
}
```

**hosts/laptop/hardware.nix** — hand-written hardware config:

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
  };

  # Graphics (adjust for your GPU — see hosts/nixos-desktop/hardware.nix
  # for an Nvidia example)
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

**hosts/laptop/home.nix** — the shared `home/` base provides shell, starship,
neovim, git identity, and CLI tools; only list what is extra on this machine:

```nix
{ config, pkgs, pkgs-stable, ... }:

{
  imports = [
    ../../home                     # shared base — do not duplicate its contents
    ../../desktops/home/kde.nix
  ];

  home.username = "michael";
  home.homeDirectory = "/home/michael";
  home.stateVersion = "25.05";     # match the system stateVersion

  home.packages = with pkgs; [
    # host-only packages
  ];
}
```

### Step 5: Add the Host to flake.nix

One line — `lib/mkhost.nix` wires up home-manager, agenix, stylix, and
pkgs-stable automatically:

```nix
nixosConfigurations = {
  nixos-desktop = mkHost { hostname = "nixos-desktop"; };
  laptop        = mkHost { hostname = "laptop"; };   # ← ADD THIS
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

**OR skip services that need secrets** by not importing them in
`hosts/<hostname>/default.nix`.

### Step 7: Build and Switch

```bash
cd ~/nix-config
git add .   # flakes only see git-tracked files

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
sudo chmod 600 /root/restic-password.txt

# Initialize Restic repository
sudo restic -r /backup init
# OR for off-site: sudo restic -r /mnt/external/backup init

# Reboot to ensure everything works
sudo reboot
```

## Special Cases

### WSL Instance

For Windows Subsystem for Linux (see SCOPING.md §4.4 for the design;
`hosts/wsl-work/` is a working example). The `nixos-wsl` flake input and
`profiles/wsl.nix` already exist — a new WSL host is just:

1. Create the host directory — no physical profile, no desktop, no hardware files:
   ```nix
   # hosts/<name>/default.nix
   { config, lib, pkgs, inputs, ... }:
   {
     imports = [
       ../../base
       ../../profiles/wsl.nix
       ../../users/michael.nix
       ./configuration.nix

       ../../features/containers.nix   # containers work in WSL
     ];
     system.stateVersion = "25.05";
   }
   ```
   ```nix
   # hosts/<name>/home.nix
   { config, pkgs, pkgs-stable, ... }:
   {
     imports = [ ../../home ];   # identical shell/prompt/CLI as every host
     home.username = "michael";
     home.homeDirectory = "/home/michael";
     home.stateVersion = "25.05";
   }
   ```
2. `<name> = mkHost { hostname = "<name>"; };` in flake.nix
3. On the Windows machine: import the NixOS-WSL tarball
   (github.com/nix-community/NixOS-WSL/releases), clone this repo inside it,
   `git add .`, and `sudo nixos-rebuild switch --flake .#<name>`. Restart the
   distro (`wsl --terminate <DistroName>`) so login switches to `wsl.defaultUser`.
   Sudo needs no password (NixOS-WSL default); run `passwd` to set one if desired.

Skip: btrfs-snapshots, virtualization, gaming, backup (or configure differently).
The WSL *distribution* name Windows registers is independent of the Linux
hostname; they can differ freely.

### Different User

```bash
cp users/michael.nix users/yourname.nix
nano users/yourname.nix   # change username
```

Update the import in the host's `default.nix`, and pass the user to mkHost:

```nix
mkHost { hostname = "laptop"; user = "yourname"; }
```

## Troubleshooting

### Build Fails: "path does not exist"
- Run `git add .` — flakes only see git-tracked files
- Check all import paths in your host's `default.nix`
- Ensure you copied `hardware-configuration.nix` into the host directory

### Build Fails: "option does not exist"
- Comment out features you don't need
- Check for hardware-specific options (Nvidia on AMD laptop)

### Secrets Error
- Don't import services that need secrets
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
- [ ] User can login; shell is fish with starship prompt
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
