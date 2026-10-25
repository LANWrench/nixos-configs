{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# wsl-work — the machine's full recipe. Everything this host runs is imported
# here; nothing is pulled in implicitly.
{
  imports = [
    # Every machine (system + home-manager): shell, git, neovim, SSH, user.
    # Identical shell/prompt/CLI experience as every other host.
    ../../common

    # Platform: WSL (replaces platform/physical.nix; no hardware files, no
    # desktop). Provides the WSL kernel, interop, and default user.
    ../../platform/wsl.nix

    # Features (opt-in) — WSL-appropriate only
    ../../features/containers.nix # Podman/OCI containers

    # Deliberately NOT imported on WSL:
    #   platform/physical.nix         (audio/NetworkManager/printing)
    #   features/btrfs-snapshots.nix  (WSL manages its own vhdx filesystem)
    #   features/backup.nix           (back up from Windows / the WSL host instead)
    #   features/virtualization.nix   (nested virt is impractical under WSL)
    #   features/gaming.nix           (desktop only)
    #   any desktops/*                (use WSLg / Windows apps)
  ];

  # ===== Host settings =====
  # (hostname is set by mkHost in lib/mkhost.nix)
  time.timeZone = "America/Chicago";

  # No password needed: NixOS-WSL sets security.sudo.wheelNeedsPassword = false,
  # and WSL logs in without authentication. Run `passwd` to set one if desired.

  # No firewall ports opened by default; WSL shares the Windows network stack.
  # networking.firewall.allowedTCPPorts = [ ];

  # This machine's user apps (work tooling goes here)
  home-manager.users.michael.home.packages = with pkgs; [
    # e.g. azure-cli, kubectl, terraform, gh — add what this work box needs
  ];

  # stateVersion (system and home) is frozen at the release this machine was
  # INSTALLED with. Never bump it when updating.
  system.stateVersion = "25.05";
  home-manager.users.michael.home.stateVersion = "25.05";
}
