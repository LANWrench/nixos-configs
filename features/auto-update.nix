{ config, pkgs, lib, ... }:

let
  flakeDir = "/home/michael/nix-config";
  host = config.networking.hostName;

  # Build-before-commit auto-update.
  #
  # The stock `system.autoUpgrade` with --commit-lock-file commits the new
  # flake.lock DURING evaluation, i.e. BEFORE the build runs. So when an
  # upstream package is temporarily broken (e.g. niri failing to build against
  # a bumped libdisplay-info), the lock still advances in git while the switch
  # fails — leaving you on a committed-but-unbuildable lock.
  #
  # This script instead:
  #   1. updates flake.lock in the working tree (NOT committed)
  #   2. builds the ENTIRE system closure (no switch) — niri and every other
  #      system package are part of it, so a broken package fails here
  #   3. only on a successful build: commit flake.lock and switch
  #   4. on failure: revert flake.lock, leaving git and the running system
  #      exactly as they were, and exit non-zero so the failure is visible
  #      (systemctl status / journalctl, and the terminal health banner).
  updateScript = pkgs.writeShellApplication {
    name = "nixos-auto-update";
    runtimeInputs = [ pkgs.git pkgs.nix pkgs.nixos-rebuild ];
    text = ''
      set -euo pipefail
      cd "${flakeDir}"

      echo "==> Updating flake inputs (lock updated in working tree, not committed)"
      nix --extra-experimental-features 'nix-command flakes' flake update

      # Nothing changed? Then there is nothing to build or commit.
      if git diff --quiet -- flake.lock; then
        echo "==> flake.lock unchanged; nothing to update"
        exit 0
      fi

      echo "==> Building the full system closure (no switch yet)"
      # This is the gate: the toplevel closure includes niri and everything
      # else, so a broken package makes this fail before we commit or switch.
      if ! nix --extra-experimental-features 'nix-command flakes' build --no-link -L \
        "${flakeDir}#nixosConfigurations.${host}.config.system.build.toplevel"; then
        echo "!! Build failed — reverting flake.lock; git and running system left untouched"
        git checkout -- flake.lock
        exit 1
      fi

      echo "==> Build succeeded; committing flake.lock and switching"
      # Commit only flake.lock, never other working-tree changes.
      git add -- flake.lock
      git commit -m "flake.lock: weekly auto-update" -- flake.lock
      nixos-rebuild switch --flake "${flakeDir}#${host}"
      echo "==> Update complete"
    '';
  };
in
{
  # ===== AUTOMATIC SYSTEM UPDATES (build-before-commit) =====
  # Creates nixos-upgrade.service (the update) + nixos-upgrade.timer (weekly).
  # The unit name is kept as "nixos-upgrade" so the terminal health banner's
  # upgrade-recency / last-run-failed checks keep working unchanged.
  #
  # Useful commands:
  #   sudo systemctl start nixos-upgrade.service    # Run update now
  #   systemctl status nixos-upgrade.service        # Check status / last result
  #   journalctl -u nixos-upgrade.service           # View logs (incl. build errors)
  #   systemctl list-timers | grep nixos-upgrade    # Check schedule

  systemd.services.nixos-upgrade = {
    description = "NixOS build-before-commit auto-update";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe updateScript;
    };
  };

  systemd.timers.nixos-upgrade = {
    description = "Weekly NixOS auto-update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      RandomizedDelaySec = "45min";
      Persistent = true; # catch up on a missed run after the machine was off
    };
  };

  # REQUIRED: root runs the update against the user-owned git repo. Git 2.35.2+
  # needs explicit trust for cross-user repo access, and a committer identity.
  environment.etc."gitconfig".text = ''
    [safe]
        directory = /home/michael/nix-config
    [user]
        name = NixOS Auto-Update
        email = nixos-upgrade@nixos-desktop
  '';

  # Automatic garbage collection (runs as nix-gc.service)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Nix store optimization (runs as nix-optimise.service)
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
