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

    # Optional features (can be disabled per-host)
    ../../features/btrfs-snapshots.nix     # Local /home snapshots (fast recovery)
    ../../features/backup.nix              # Restic off-site backup (disaster recovery)
    ../../features/auto-update.nix         # Weekly automatic system updates
    ../../features/virtualization.nix      # libvirt/QEMU for VMs
    ../../features/containers.nix          # Podman/OCI containers
    ../../features/gaming.nix              # Gaming-specific programs
    ../../features/terminal-status-banner.nix  # Health check on terminal startup

    # Services (optional, host-specific)
    ../../modules/services/searxng.nix  # Private search engine

    # Desktop Environment
    ../../desktops/cosmic.nix
  ];

  system.stateVersion = "25.05";
}
