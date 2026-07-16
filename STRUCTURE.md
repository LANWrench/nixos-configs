# NixOS Configuration Structure

This NixOS configuration supports multiple hosts (desktops, laptops, WSL instances)
from a shared, layered base. See [SCOPING.md](SCOPING.md) for the design rationale.

## The Three Layers

```
┌───────────────────────────────────────────────────────────┐
│ Layer 3: hosts/<name>/          "This machine"            │
│   hardware, timezone, DE choice, feature picks,           │
│   host-only packages                                      │
├───────────────────────────────────────────────────────────┤
│ Layer 2: profiles/, features/,  "Kinds of machines /      │
│          desktops/               optional capabilities"   │
├───────────────────────────────────────────────────────────┤
│ Layer 1: base/ + home/          "Every machine, period"   │
│   git, ripgrep, curl, SSH, fish, starship, fzf,           │
│   tmux, neovim, git identity                              │
└───────────────────────────────────────────────────────────┘
```

Lower layers never reference higher ones.

## Directory Structure

```
nix-config/
├── flake.nix                    # Inputs + one line per host
├── lib/
│   └── mkhost.nix               # Host builder (home-manager/agenix/pkgs-stable wiring)
│
├── base/                        # Layer 1 (system): EVERY host, incl. WSL
│   ├── default.nix              # Aggregator — hosts import ../../base
│   ├── core.nix                 # git, ripgrep, curl, vim, dbus
│   ├── nix.nix                  # Nix settings (flakes)
│   └── security.nix             # SSH daemon, polkit, FUSE
│
├── home/                        # Layer 1 (home-manager): EVERY host
│   ├── default.nix              # Aggregator — host home.nix imports ../../home
│   ├── shell.nix                # fish, bash
│   ├── starship.nix             # Prompt
│   ├── neovim.nix               # Neovim (+ neovim-config.lua)
│   ├── git.nix                  # Git identity — defined ONCE
│   └── cli.nix                  # tmux, fzf, btop, claude-code
│
├── profiles/                    # Layer 2: bundles for kinds of machines
│   ├── physical.nix             # Audio, NetworkManager, printing, fonts, gparted
│   └── wsl.nix                  # NixOS-WSL (no audio/NetworkManager/printing)
│                                # (future: laptop.nix)
│
├── features/                    # Layer 2: à la carte system capabilities
│   ├── btrfs-snapshots.nix      # Snapper snapshots of /home
│   ├── backup.nix               # Restic off-site backup
│   ├── auto-update.nix          # Weekly auto-updates + GC + store optimise
│   ├── virtualization.nix       # libvirt/QEMU (adds libvirtd group)
│   ├── containers.nix           # Podman/OCI containers
│   ├── gaming.nix               # gamemode, gamescope
│   └── terminal-status-banner.nix  # nixos-health terminal banner
│
├── desktops/                    # Layer 2: DE pairs (system + home halves)
│   ├── gnome.nix  kde.nix  niri.nix  cosmic.nix
│   └── home/
│       └── gnome.nix  kde.nix  niri.nix  cosmic.nix
│
├── users/
│   └── michael.nix              # Account, groups, shell
│
├── modules/                     # Reusable system services
│   ├── restic.nix  snapper.nix
│   └── services/                # Optional services (searxng, caddy)
│
├── secrets/                     # agenix encrypted secrets (safe to commit)
│
└── hosts/                       # Layer 3: one directory per machine
    ├── nixos-desktop/
    │   ├── default.nix              # The machine's full recipe (imports)
    │   ├── hardware-configuration.nix  # Generated — never hand-edit
    │   ├── hardware.nix             # Hand-written: Nvidia, boot, BTRFS
    │   ├── configuration.nix        # Timezone, firewall ports
    │   └── home.nix                 # Host-only packages + DE home module
    └── wsl-work/                    # WSL instance (no hardware files, no DE)
        ├── default.nix              # base + profiles/wsl.nix + containers
        ├── configuration.nix        # Timezone
        └── home.nix                 # ../../home only + work packages
```

## Where Does a New Thing Go?

Ask: **"Would I want this on a WSL instance with no screen?"**

```
Need it on every machine incl. WSL?
├── yes, CLI/user tool        → home/cli.nix
├── yes, system tool/daemon   → base/core.nix
├── only physical machines    → profiles/physical.nix
├── part of an optional role  → features/<feature>.nix (create if new)
└── only one machine          → hosts/<name>/home.nix or configuration.nix
```

## How to Add a New Host

1. **Create the host directory** and copy the generated hardware config:
   ```bash
   mkdir -p hosts/laptop
   sudo cp /etc/nixos/hardware-configuration.nix hosts/laptop/
   ```

2. **Create `hosts/laptop/default.nix`** — the machine's recipe:
   ```nix
   { config, lib, pkgs, inputs, ... }:

   {
     imports = [
       ../../base                     # Universal base (always)
       ../../profiles/physical.nix    # Real hardware (skip on WSL)
       ../../users/michael.nix

       ./hardware-configuration.nix
       ./hardware.nix                 # GPU/boot config (create as needed)
       ./configuration.nix

       # Features — pick what this machine needs
       ../../features/btrfs-snapshots.nix
       ../../features/backup.nix

       # Desktop environment
       ../../desktops/kde.nix         # Or gnome, niri, cosmic
     ];

     system.stateVersion = "25.05";   # The release this machine was INSTALLED with
   }
   ```

3. **Create `hosts/laptop/configuration.nix`** (hostname comes from mkHost):
   ```nix
   { config, pkgs, ... }:

   {
     time.timeZone = "America/Chicago";
     # laptop extras, e.g. services.tlp.enable = true;
   }
   ```

4. **Create `hosts/laptop/home.nix`**:
   ```nix
   { config, pkgs, pkgs-stable, ... }:

   {
     imports = [
       ../../home                     # Shared shell/prompt/CLI base
       ../../desktops/home/kde.nix
     ];

     home.username = "michael";
     home.homeDirectory = "/home/michael";
     home.stateVersion = "25.05";

     home.packages = with pkgs; [
       # host-only packages
     ];
   }
   ```

5. **Add one line to `flake.nix`**:
   ```nix
   laptop = mkHost { hostname = "laptop"; };
   ```

6. **Build**:
   ```bash
   git add .   # flakes only see tracked files
   sudo nixos-rebuild switch --flake .#laptop
   ```

## How to Add a WSL Host

Same as above, but (see `hosts/wsl-work/` for a working example):
- Do NOT import `profiles/physical.nix`, any `desktops/*`, or hardware files
- Import `profiles/wsl.nix` instead (nixos-wsl module, `wsl.enable`, default user)
- `home.nix` imports only `../../home` — same shell, prompt, and CLI
  tooling as every other machine, for free

## Switching Desktop Environments

Change two imports for the host:
- `hosts/<name>/default.nix`: `../../desktops/gnome.nix` → `../../desktops/kde.nix`
- `hosts/<name>/home.nix`: `../../desktops/home/gnome.nix` → `../../desktops/home/kde.nix`

## Maintenance

```bash
# Update flake inputs, test, then commit the lockfile
nix flake update
sudo nixos-rebuild test --flake .#nixos-desktop
git commit -m "flake update" flake.lock

# Apply config changes
sudo nixos-rebuild test --flake .#nixos-desktop     # try without boot entry
sudo nixos-rebuild switch --flake .#nixos-desktop   # activate + boot default

# Clean old generations (also automatic weekly via features/auto-update.nix)
sudo nix-collect-garbage --delete-older-than 30d
```

### Workflow across machines

The GitHub repo is the source of truth. `flake.lock` is always committed, so every
machine builds identical package versions. Day-to-day:

1. Edit on any machine → `nixos-rebuild test` → commit → push
2. Other machines: `git pull && sudo nixos-rebuild switch --flake .#<host>`

## Conventions

- `hardware-configuration.nix` is generated by `nixos-generate-config` — never hand-edit.
  Hand-written hardware config (GPU drivers, boot) goes in `hardware.nix`.
- `stateVersion` (system and home) is frozen at each machine's install-time release.
  Do not bump it when updating.
- Features are never imported by aggregators — every host opts in explicitly, so a
  host's full recipe is readable in its `default.nix`.
- Features are self-contained: a feature adds its own packages, services, and user
  groups (e.g. `virtualization.nix` adds `libvirtd`).
