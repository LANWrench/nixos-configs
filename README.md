# NixOS Configuration

Multi-host NixOS configuration using flakes, built in three layers: a universal
base (every machine, including WSL), profiles/features for kinds of machines and
optional capabilities, and thin per-host directories.

## Quick Start

```bash
# Clone this repo
git clone git@github.com:LANWrench/nixos-configs.git ~/nix-config
cd ~/nix-config

# Build for your host
sudo nixos-rebuild switch --flake .#nixos-desktop
```

## Hosts

- **nixos-desktop** - Main desktop with Nvidia GPU, COSMIC, gaming setup
- **laptop** - (future) Laptop configuration
- **wsl** - (future) WSL instance

## Structure

```
nix-config/
├── flake.nix                # Inputs + one line per host
├── lib/mkhost.nix           # Host builder (HM/agenix/pkgs-stable wiring)
├── base/                    # System base: EVERY host, incl. WSL
├── home/                    # Home-manager base: shell, starship, neovim,
│                            #   git identity, CLI tools — every host
├── profiles/
│   └── physical.nix         # Audio, NetworkManager, printing, fonts
├── features/                # Opt-in: gaming, backup, virtualization,
│                            #   containers, snapshots, auto-update, banner
├── desktops/                # DE configs (system + home halves)
├── users/michael.nix        # User account definition
├── modules/                 # Reusable services (restic, snapper, searxng, caddy)
├── secrets/                 # agenix encrypted secrets
└── hosts/                   # One directory per machine
    └── nixos-desktop/       # default.nix, hardware*, configuration.nix, home.nix
```

See [STRUCTURE.md](STRUCTURE.md) for detailed documentation and
[SCOPING.md](SCOPING.md) for the design rationale.

## Adding a New Host

1. `mkdir hosts/<name>` and copy `/etc/nixos/hardware-configuration.nix` into it
2. Write `default.nix` (imports: base + profile + features + DE),
   `configuration.nix` (timezone), and `home.nix` (imports `../../home` + extras)
3. Add one line to `flake.nix`:
   ```nix
   <name> = mkHost { hostname = "<name>"; };
   ```
4. `git add . && sudo nixos-rebuild switch --flake .#<name>`

Full walkthrough: [SETUP-NEW-HOST.md](SETUP-NEW-HOST.md)

## Switching Desktop Environments

Change two imports for the host, then rebuild:

- `hosts/<name>/default.nix`: `../../desktops/gnome.nix` → `../../desktops/kde.nix`
- `hosts/<name>/home.nix`: `../../desktops/home/gnome.nix` → `../../desktops/home/kde.nix`

## Maintenance

### Update System
```bash
nix flake update
sudo nixos-rebuild test --flake .#nixos-desktop   # verify first
sudo nixos-rebuild switch --flake .#nixos-desktop
git commit -m "flake update" flake.lock && git push
```

`flake.lock` is always committed — it is what keeps every machine on identical
package versions. Other machines just `git pull` and rebuild.

### Clean Old Generations
```bash
# Also runs automatically weekly via features/auto-update.nix
sudo nix-collect-garbage --delete-older-than 30d
```

### Check Backups
```bash
sudo snapper -c home list                                   # local snapshots
sudo restic -r /backup snapshots                            # restic backups
journalctl -u restic-backups-fullMachine.service -n 100     # backup logs
```

## Backup Strategy

**Fast Recovery (Local):** Snapper hourly snapshots of `/home` only, at
`/home/.snapshots/` (`features/btrfs-snapshots.nix`).

**Disaster Recovery (Off-site):** Restic daily backups via `features/backup.nix`
(currently to `/backup` — configure off-site!).

## Automatic Updates

Weekly automatic updates are enabled via `features/auto-update.nix`:
- Updates all flake inputs, rebuilds, commits the lockfile
- Weekly garbage collection and store optimisation
- Check status: `systemctl status nixos-upgrade.timer`

## Documentation

- [SETUP-NEW-HOST.md](SETUP-NEW-HOST.md) - Complete guide for deploying to a fresh NixOS system
- [STRUCTURE.md](STRUCTURE.md) - Detailed structure documentation
- [SCOPING.md](SCOPING.md) - Design rationale and migration plan

## License

Personal configuration - feel free to use as reference.
