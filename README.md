# NixOS Configuration

Multi-host NixOS configuration (flakes + home-manager) for every machine —
desktops, laptops, WSL — from one shared base.

**Organizing rule: one topic, one file.** Each file holds *both* the system
side and the user (home-manager) side of its topic, via
`home-manager.users.michael = { ... };`. To change niri, open
`desktops/niri.nix`; to see what a machine runs, open
`hosts/<name>/default.nix`.

## Layout

```
nix-config/
├── flake.nix                 # Inputs + one line per host
├── lib/mkhost.nix            # Host builder (home-manager/agenix/stylix/pkgs-stable wiring)
│
├── common/                   # EVERY machine, period (incl. WSL)
│   ├── default.nix           #   aggregator — hosts import ../../common
│   ├── system.nix            #   Nix settings, SSH daemon, polkit, dbus, FUSE
│   ├── user.nix              #   michael's account + home-manager basics
│   ├── cli.nix               #   shared CLI packages + tmux, fzf, btop, claude-code
│   ├── shell.nix             #   fish, bash
│   ├── starship.nix          #   prompt
│   ├── git.nix               #   git identity — defined ONCE
│   ├── ssh.nix               #   SSH client aliases for the homelab fleet
│   └── neovim/               #   default.nix + config.lua
│
├── platform/                 # What the platform gives you — pick ONE per host
│   ├── physical.nix          #   real hardware: audio, NetworkManager, printing, gparted
│   └── wsl.nix               #   NixOS-WSL (Windows provides network/audio/display)
│
├── desktops/                 # Desktop environment (system + home in one file)
│   ├── niri.nix              #   niri + Dank Material Shell + Stylix theming
│   └── fonts.nix             #   fonts — imported by niri.nix (and any future desktop)
│
├── features/                 # Opt-in capabilities, each fully self-contained
│   ├── auto-update.nix       #   weekly build-before-commit update + GC + store optimise
│   ├── backup.nix            #   restic off-site backup
│   ├── btrfs-snapshots.nix   #   snapper snapshots of /home
│   ├── containers.nix        #   podman
│   ├── gaming.nix            #   gamemode, gamescope, steam, emulators
│   ├── health-banner.nix     #   `nixos-health` script + the hook that runs it per terminal
│   ├── local-llm.nix         #   llama.cpp server + Hermes Agent
│   ├── virtualization.nix    #   libvirt/QEMU (adds libvirtd group)
│   └── voice-capture.nix     #   EVISTR recorder → whisper → Obsidian (+ voice-capture/)
│
├── hosts/                    # One folder per machine
│   ├── nixos-desktop/
│   │   ├── default.nix           # THE RECIPE: imports + timezone/firewall/stateVersion
│   │   ├── hardware.nix          # hand-written: Nvidia, boot, CUDA tuning, BTRFS, USB
│   │   ├── hardware-generated.nix  # from nixos-generate-config — never hand-edit
│   │   └── apps.nix              # this machine's user apps and their settings
│   └── wsl-work/
│       └── default.nix           # small host: recipe + apps in one file
│
├── secrets/                  # agenix-encrypted secrets (safe to commit)
└── docs/
    ├── new-host.md           # Step-by-step: adding a machine (physical or WSL)
    └── design-history.md     # Original design doc (historical; layout has since changed)
```

Lower layers never reference higher ones: `common/` knows nothing about
platforms, desktops, or hosts.

## Where is…?

| Looking for | File |
|---|---|
| A package on every machine | `common/cli.nix` |
| fish / bash / prompt / neovim / git identity | `common/shell.nix`, `starship.nix`, `neovim/`, `git.nix` |
| SSH aliases (`ssh edge01`) | `common/ssh.nix` |
| My user account, groups, login shell | `common/user.nix` |
| SSH server, polkit, flakes setting | `common/system.nix` |
| Audio, Wi-Fi/NetworkManager, printing | `platform/physical.nix` |
| Fonts | `desktops/fonts.nix` |
| Desktop look, theme (Stylix), greeter, portals | `desktops/niri.nix` |
| Shell key bindings (same on every machine) | `common/shell.nix` |
| A desktop-only app (browser, Discord, VS Code, OBS…) | `hosts/nixos-desktop/apps.nix` |
| opencode / LiteLLM config | `hosts/nixos-desktop/apps.nix` |
| Steam and games | `features/gaming.nix` |
| GPU drivers, kernel, boot loader, CUDA | `hosts/nixos-desktop/hardware.nix` |
| Disk/filesystem mounts | `hosts/nixos-desktop/hardware-generated.nix` |
| Timezone, firewall ports, stateVersion | `hosts/<name>/default.nix` |
| Update schedule, garbage collection | `features/auto-update.nix` |
| Backups / snapshots | `features/backup.nix`, `features/btrfs-snapshots.nix` |
| Terminal health banner | `features/health-banner.nix` |
| Local LLM server | `features/local-llm.nix` (GPU tuning in `hardware.nix`) |
| Which secrets exist + who can decrypt | `secrets/secrets.nix` |

## Where does a new thing go?

```
Want it on every machine?               → common/  (packages: common/cli.nix)
Every physical machine (or every WSL)?  → platform/<platform>.nix
Only with a desktop / screen?           → desktops/niri.nix (fonts: desktops/fonts.nix)
A bundle some machines opt into?        → features/<name>.nix (create if new)
Just this one machine?                  → hosts/<name>/  (apps: apps.nix,
                                            hardware: hardware.nix, else default.nix)
```

How shared and per-host settings combine:

- **Lists add up.** `common/cli.nix` and `hosts/<name>/apps.nix` both add
  packages; each host gets the shared ones plus its own.
- **Hosts extend, never override.** `common/cli.nix` enables btop; the desktop's
  `hardware.nix` picks the CUDA build via `programs.btop.package`. No conflict,
  because `common/` doesn't set `package`.
- **Settings that differ per machine don't go in `common/` at all** — each host
  sets them (e.g. `time.timeZone`). No `mkDefault`/conditional tricks: if a
  setting is in `common/`, every machine has it.
- **The module that creates a need owns it.** `platform/physical.nix` enables
  NetworkManager, so it adds the `networkmanager` group;
  `features/virtualization.nix` adds `libvirtd`.

## Common tasks

```bash
# Try a change without making it the boot default, then make it permanent
sudo nixos-rebuild test   --flake .#nixos-desktop
sudo nixos-rebuild switch --flake .#nixos-desktop

# New files are invisible to flakes until git tracks them
git add <new-file>

# Update inputs by hand (also happens weekly: features/auto-update.nix)
nix flake update && sudo nixos-rebuild test --flake .#nixos-desktop
git commit -m "flake update" flake.lock

# Roll back
sudo nixos-rebuild switch --rollback
```

**Other desktops:** only niri is kept. KDE, GNOME and COSMIC configs were
removed (Oct 2026) but live in git history — `git log --all -- desktops/kde.nix`
finds them. Adding one back = a new `desktops/<de>.nix` that imports
`./fonts.nix`, swapped in for the niri import in `hosts/<name>/default.nix`.

**Add a host:** one folder in `hosts/` + one line in `flake.nix` — see
[docs/new-host.md](docs/new-host.md).

**Verify a pure refactor:** the system derivation must not change —
```bash
nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```
Run before and after; identical output means identical system. If it differs,
`nix run nixpkgs#nix-diff -- <old.drv> <new.drv>` shows exactly what changed.

## Workflow across machines

The GitHub repo is the source of truth and `flake.lock` is always committed, so
every machine builds identical package versions.

1. Edit on any machine → `nixos-rebuild test` → commit → push
2. Other machines: `git pull && sudo nixos-rebuild switch --flake .#<host>`

## SSH to the homelab fleet

`common/ssh.nix` defines `ssh <alias>` for each fleet node (all log in as
`deploy`), on every machine. Aliases mirror the Colmena node names in
`~/nix-fleet/flake.nix` (a separate repo) — they are **not** linked
automatically, so update `common/ssh.nix` when a node is added, removed, or
re-IP'd there.

## Conventions

- `hardware-generated.nix` comes from `nixos-generate-config` — never hand-edit.
  Hand-written hardware config goes in `hardware.nix`.
- `stateVersion` (system and home) is frozen at each machine's install-time
  release, set side by side in `hosts/<name>/default.nix`. Never bump it.
- Features are never imported by aggregators — every host opts in explicitly,
  so a host's full recipe is readable in its `default.nix`.
- `nixpkgs-stable` in `flake.nix` is a hardcoded release that `nix flake update`
  never bumps; the health banner warns when it falls behind.
