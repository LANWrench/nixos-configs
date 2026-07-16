{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Universal base (every host, incl. WSL)
    ../../base

    # WSL platform profile (replaces profiles/physical.nix; no hardware files,
    # no desktop). Provides the WSL kernel, interop, and default user.
    ../../profiles/wsl.nix

    # User configuration
    ../../users/michael.nix

    # Host-specific configuration
    ./configuration.nix

    # Optional features — WSL-appropriate only
    ../../features/containers.nix # Podman/OCI containers

    # Deliberately NOT imported on WSL:
    #   profiles/physical.nix         (audio/NetworkManager/printing/fonts)
    #   features/btrfs-snapshots.nix  (WSL manages its own vhdx filesystem)
    #   features/backup.nix           (back up from Windows / the WSL host instead)
    #   features/virtualization.nix   (nested virt is impractical under WSL)
    #   features/gaming.nix           (desktop only)
    #   any desktop (niri/kde/...)    (use WSLg / Windows apps)
  ];

  system.stateVersion = "25.05";
}
