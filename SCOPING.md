# Scoping Document: Modular Multi-Host NixOS Configuration

**Status:** Implemented (Phases 1–6 complete; Phase 7 WSL host deferred until needed)
**Date:** 2026-07-03
**Repo goal:** A single GitHub repository that configures every machine — desktops with
varying GPUs, laptops, and WSL instances — from one shared, layered base.

---

## 1. Goals

1. **Shared base first.** Packages and components every system needs (git, ripgrep, curl,
   fish, starship, fzf, tmux, neovim, git identity) are defined exactly once and inherited
   by every host automatically.
2. **Hardware independence.** GPU drivers, boot config, and filesystems are strictly
   per-host. Adding a machine with different hardware never touches shared files.
3. **WSL-ready.** The base layer must contain nothing that assumes physical hardware or a
   display, so a WSL host can consume it unchanged.
4. **Simplicity over cleverness.** Plain imports and small aggregator files — no custom
   option system, no auto-discovery magic. Anyone reading `hosts/<name>/default.nix`
   should see the machine's entire recipe.
5. **Low-friction maintenance.** Adding a host, a package, or a feature has a documented,
   mechanical procedure (Section 7).

## 2. Current State Assessment

The repo is already partially modularized. What works today:

- ✅ `base/` exists with system-level modules (core, security, audio, networking, printing)
- ✅ `hosts/nixos-desktop/` composes base + features + a desktop environment
- ✅ `features/` provides à la carte system capabilities (gaming, backup, virtualization…)
- ✅ `desktops/` cleanly separates DE choice (system + home halves)
- ✅ Flake with pinned inputs, `pkgs-stable` escape hatch, agenix secrets

Gaps that block the stated goals:

| # | Gap | Impact |
|---|-----|--------|
| G1 | **No shared home-manager base.** Fish, starship enablement, git identity, fzf, tmux, bash and common CLI packages all live inside `hosts/nixos-desktop/home.nix`. | Every new host copy-pastes ~190 lines; shell/prompt drift between machines is guaranteed. |
| G2 | **Flake boilerplate per host.** Each host repeats ~25 lines of home-manager + agenix + `pkgs-stable` wiring (and imports nixpkgs-stable twice). | Error-prone; adding hosts is noisy. |
| G3 | **`hardware-configuration.nix` at repo root** and imported by the desktop host. | Second host would inherit the desktop's disks/filesystems. Must be per-host. |
| G4 | **Base assumes physical desktop hardware.** `audio.nix`, `printing.nix`, `networking.nix` (NetworkManager) don't apply to WSL; `base/core.nix` hardcodes `"x86_64-linux"` for agenix. | WSL host can't import base as-is. |
| G5 | **Dead files.** Root `configuration.nix` and `home.nix` are marked deprecated; `MIGRATION-BACKUP-CLEANUP.md` is a one-time artifact. | Confusing for the GitHub-repo use case; new-machine readers may edit the wrong file. |
| G6 | **User-specific values scattered.** Git identity in host home.nix; `safe.directory = /home/michael/nix-config` hardcoded in `base/security.nix`. | Duplication when host count grows. |

## 3. Target Architecture

Three layers, applied in order. Lower layers never reference higher ones.

```
┌───────────────────────────────────────────────────────────┐
│ Layer 3: hosts/<name>/          "This machine"            │
│   hardware, hostname, DE choice, feature picks,           │
│   host-only packages                                      │
├───────────────────────────────────────────────────────────┤
│ Layer 2: profiles/, features/,  "Kinds of machines /      │
│          desktops/               optional capabilities"   │
├───────────────────────────────────────────────────────────┤
│ Layer 1: base/ + home/base      "Every machine, period"   │
│   git, ripgrep, curl, fonts, SSH, fish, starship, fzf,    │
│   tmux, neovim, git identity                              │
└───────────────────────────────────────────────────────────┘
```

### 3.1 Directory layout (target)

```
nix-config/
├── flake.nix                  # inputs + mkHost helper + one line per host
├── flake.lock                 # always committed
│
├── lib/
│   └── mkhost.nix             # host-builder helper (Section 4.1)
│
├── base/                      # Layer 1 (system): EVERY host, incl. WSL
│   ├── default.nix            # imports core.nix + security.nix + nix.nix
│   ├── core.nix               # git, ripgrep, curl, wget, vim, fonts
│   ├── nix.nix                # flakes, gc, nix settings
│   └── security.nix           # SSH daemon, polkit
│
├── home/                      # Layer 1 (home-manager): EVERY host  ← NEW
│   ├── default.nix            # imports everything below
│   ├── shell.nix              # fish, bash, aliases, sessionPath
│   ├── starship.nix           # moved from modules/starship.nix
│   ├── neovim.nix             # moved from modules/ (+ neovim-config.lua)
│   ├── git.nix                # identity, defaultBranch — defined ONCE
│   └── cli.nix                # fzf, tmux, btop (no CUDA), CLI packages
│
├── profiles/                  # Layer 2: bundles for kinds of machines ← NEW
│   ├── physical.nix           # audio + networking(NM) + printing + bluetooth
│   ├── laptop.nix             # physical.nix + tlp/power + lid/suspend
│   └── wsl.nix                # nixos-wsl settings, no audio/NM/printing
│
├── features/                  # Layer 2: à la carte (unchanged concept)
│   ├── gaming.nix  backup.nix  virtualization.nix  containers.nix
│   ├── btrfs-snapshots.nix  auto-update.nix  terminal-status-banner.nix
│
├── desktops/                  # Layer 2: DE pairs (unchanged)
│   ├── gnome.nix kde.nix cosmic.nix niri.nix
│   └── home/…
│
├── users/
│   └── michael.nix            # account, groups, shell (unchanged)
│
├── modules/services/          # optional services (searxng, caddy) (unchanged)
├── secrets/                   # agenix (unchanged)
│
├── hosts/                     # Layer 3: one directory per machine
│   ├── nixos-desktop/
│   │   ├── default.nix        # the machine's full recipe (imports)
│   │   ├── hardware-configuration.nix   # ← moved from repo root
│   │   ├── hardware.nix       # Nvidia, boot, btrfs
│   │   ├── configuration.nix  # hostname, timezone, firewall
│   │   └── home.nix           # host-only packages + DE home module
│   ├── laptop/                # future
│   └── wsl/                   # future
│
└── docs: README.md  STRUCTURE.md  SETUP-NEW-HOST.md  SCOPING.md
```

### 3.2 The base/host split rule

A single question decides where something goes:

> **"Would I want this on a WSL instance with no screen?"**

- Yes → `base/` (system) or `home/` (user). Examples: ripgrep, git, fish, starship,
  fzf, tmux, neovim, git identity, SSH settings, nix GC policy.
- Yes, but only on real hardware → `profiles/physical.nix` (audio, NetworkManager,
  printing) or `profiles/laptop.nix` (power management).
- Only some machines, by choice → `features/` (gaming, virtualization, backup).
- Only this machine → `hosts/<name>/` (GPU driver, CUDA overrides, firewall ports,
  Steam, OBS).

Concretely, from the current desktop `home.nix`, the following move **into `home/`**:
`programs.fish`, `programs.bash`, `programs.starship`, `programs.tmux`, `programs.fzf`,
`programs.git` (identity), neovim, `home.sessionPath`, `xdg.enable`,
`programs.home-manager.enable`, plain `btop`. Everything hardware- or role-specific stays
in the host file: CUDA-built btop/OBS, Steam/gaming apps, VS Code + azure/dotnet stack,
desktop GUI apps, themes.

`home.username` / `home.homeDirectory` / `stateVersion` stay per-host (stateVersion must
be frozen at each machine's install-time value).

## 4. Design Details

### 4.1 `mkHost` helper — kills the flake boilerplate (G2)

`lib/mkhost.nix`:

```nix
# Builds a nixosSystem with home-manager, agenix, and pkgs-stable pre-wired.
{ inputs }:
{ hostname, system ? "x86_64-linux", user ? "michael", extraModules ? [ ] }:
let
  pkgs-stable = import inputs.nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs pkgs-stable; };
  modules = [
    { nixpkgs.config.allowUnfree = true; networking.hostName = hostname; }
    ../hosts/${hostname}
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        backupFileExtension = "backup";
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit pkgs-stable; };
        users.${user}.imports = [
          ../hosts/${hostname}/home.nix
          inputs.stylix.homeModules.stylix
        ];
      };
    }
  ] ++ extraModules;
}
```

`flake.nix` outputs then collapse to:

```nix
outputs = inputs@{ nixpkgs, ... }:
  let mkHost = import ./lib/mkhost.nix { inherit inputs; };
  in {
    nixosConfigurations = {
      nixos-desktop = mkHost { hostname = "nixos-desktop"; };
      # laptop      = mkHost { hostname = "laptop"; };
      # wsl         = mkHost { hostname = "wsl"; };
    };
  };
```

Notes: hostname moves into `mkHost` (delete it from `hosts/*/configuration.nix`);
`system` is a parameter, which also fixes the hardcoded `"x86_64-linux"` agenix package in
`base/core.nix` (use `inputs.agenix.packages.${pkgs.system}.default` there).

### 4.2 Aggregator `default.nix` files (G1, G4)

`base/default.nix` and `home/default.nix` each just import their siblings. Hosts then
write two lines instead of ten:

```nix
# hosts/laptop/default.nix
imports = [
  ../../base                      # Layer 1 system
  ../../profiles/laptop.nix       # Layer 2 machine-kind
  ../../users/michael.nix
  ./hardware-configuration.nix
  ./hardware.nix
  ./configuration.nix
  ../../features/backup.nix       # à la carte picks stay explicit
  ../../desktops/kde.nix
];
```

```nix
# hosts/laptop/home.nix
imports = [ ../../home  ../../desktops/home/kde.nix ];
home.packages = with pkgs; [ /* host-only extras */ ];
```

Rule: `base/default.nix` and `home/default.nix` may only contain things that pass the WSL
test (3.2). `features/` are **never** imported by an aggregator — always explicitly per
host, so a host's recipe stays visible in one file.

### 4.3 Per-host hardware (G3)

- `git mv hardware-configuration.nix hosts/nixos-desktop/` and fix the import.
- Every future host gets its own copy from `nixos-generate-config` at install time.
- Convention: `hardware-configuration.nix` = generated, never hand-edited;
  `hardware.nix` = hand-written (GPU driver, boot loader, kernel params).

### 4.4 WSL support (G4)

1. Add input: `nixos-wsl.url = "github:nix-community/NixOS-WSL";`
2. `profiles/wsl.nix`:
   ```nix
   { inputs, ... }: {
     imports = [ inputs.nixos-wsl.nixosModules.default ];
     wsl.enable = true;
     wsl.defaultUser = "michael";
     # no audio / NetworkManager / printing — WSL uses Windows' networking
   }
   ```
3. `hosts/wsl/` imports `../../base`, `../../profiles/wsl.nix`, `../../users/michael.nix`
   — no hardware-configuration.nix, no desktop, no physical profile. Its `home.nix`
   imports `../../home` only. Because Layer 1 is display-free by construction, the WSL
   host gets the identical shell/prompt/CLI experience with zero extra work.
4. `users/michael.nix` currently adds groups like `libvirtd`/`video` unconditionally;
   move feature-tied groups into their feature module
   (e.g. `users.users.michael.extraGroups = [ "libvirtd" ];` inside
   `features/virtualization.nix` — NixOS merges the lists).

*Optional later:* a standalone `homeConfigurations` flake output for non-NixOS machines
(Ubuntu WSL, servers) reusing the same `home/` layer. Not in initial scope.

### 4.5 Cleanup (G5, G6)

- Delete root `configuration.nix`, `home.nix` (git history preserves them), and
  `MIGRATION-BACKUP-CLEANUP.md`.
- Git identity lives only in `home/git.nix`.
- Replace the hardcoded `safe.directory = "/home/michael/nix-config"` in
  `base/security.nix` — not needed once rebuilds run as the owning user, or generalize it.
- Update `STRUCTURE.md` and `SETUP-NEW-HOST.md` to match the new layout (their
  add-a-host instructions currently reproduce the flake boilerplate that `mkHost`
  eliminates).

## 5. Migration Plan

Each phase leaves the system fully rebuildable; verify with
`sudo nixos-rebuild test --flake .#nixos-desktop` before moving on. Commit per phase.

| Phase | Work | Risk |
|-------|------|------|
| 1 | Commit/stash current WIP changes so migration starts from a clean tree | none |
| 2 | Create `home/` (shell, starship, git, cli, neovim + aggregator); slim `hosts/nixos-desktop/home.nix` down to host-only content; move `modules/starship.nix`, `modules/neovim.nix` into `home/` | low — pure moves |
| 3 | Add `base/default.nix`; split out `profiles/physical.nix` (audio/networking/printing move out of base); update desktop host imports | low |
| 4 | Add `lib/mkhost.nix`; rewrite `flake.nix`; remove hostname from host configuration.nix | medium — verify `nix flake check` + test build |
| 5 | `git mv hardware-configuration.nix hosts/nixos-desktop/` | low |
| 6 | Cleanup: delete deprecated root files, consolidate git identity, update docs | none |
| 7 | (When needed) add `hosts/wsl/` + `profiles/wsl.nix` + nixos-wsl input | isolated |

Rollback at any point: `git revert` / previous NixOS generation from the boot menu.

## 6. GitHub Repo Workflow

- Repo is the single source of truth; every machine clones it to `~/nix-config`.
- **Always commit `flake.lock`** — this is what makes all machines bit-identical.
- Never commit: private age/SSH keys, unencrypted secrets. `secrets/*.age` are safe to
  commit (encrypted); `secrets/secrets.nix` lists public keys only.
- Day-to-day: edit → `sudo nixos-rebuild test --flake .#<host>` → commit → push;
  other machines `git pull && sudo nixos-rebuild switch --flake .#<host>`.
- Updates: `nix flake update && sudo nixos-rebuild test --flake .#<host>`, commit the
  lockfile bump on success. One machine updates the lock; the rest just pull.

## 7. Maintenance Playbook

### Adding a package — decision tree

```
Need it on every machine incl. WSL?
├── yes, CLI/user tool        → home/cli.nix
├── yes, system tool/daemon   → base/core.nix
├── only physical machines    → profiles/physical.nix (or laptop.nix)
├── part of an optional role  → features/<feature>.nix (create if new)
└── only one machine          → hosts/<name>/home.nix or configuration.nix
```

### Adding a new machine (target: ~15 minutes)

1. Install NixOS (or NixOS-WSL) minimally; clone the repo.
2. `mkdir hosts/<name>`; copy `hardware-configuration.nix` from
   `/etc/nixos/` into it.
3. Write `default.nix` (pick a profile + features + DE), a small `configuration.nix`
   (timezone, firewall), `hardware.nix` if it has a GPU, and a `home.nix` that imports
   `../../home` plus host extras. Set both `stateVersion`s to the installed release.
4. Add one line to `flake.nix`: `<name> = mkHost { hostname = "<name>"; };`
5. `sudo nixos-rebuild switch --flake .#<name>`; commit and push.

### Adding a new feature

Create `features/<name>.nix`, self-contained: services + packages + any user groups it
needs. Never import it from an aggregator; hosts opt in explicitly.

### Switching desktop environments

Change two imports for the host: `desktops/<de>.nix` in `default.nix` and
`desktops/home/<de>.nix` in `home.nix`.

### Housekeeping

- `sudo nix-collect-garbage --delete-older-than 30d` (or wire `nix.gc` into
  `base/nix.nix` so it's automatic everywhere).
- `nix flake check` before pushing; consider a GitHub Action running
  `nix flake check` + `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
  per host as a later enhancement.

## 8. Explicitly Out of Scope (for now)

- Converting features to `mkEnableOption`-style option modules — explicit imports are
  simpler and sufficient at this host count. Revisit if hosts exceed ~5.
- Standalone home-manager for non-NixOS machines (enabled by this design, not built now).
- nix-darwin, deploy-rs/colmena remote deployment, CI builds.

## 9. Success Criteria

1. `hosts/nixos-desktop` rebuilds identically (same packages/services) after migration.
2. A hypothetical `hosts/wsl` needs zero changes to any shared file.
3. A new host = one directory + one flake line; shell, prompt, git, and CLI tooling are
   identical on it with no copied configuration.
4. No file outside `hosts/` mentions specific hardware, and no file outside `home/git.nix`
   mentions the git identity.
