{ config, pkgs, ... }:

{
  # OCI containers with Podman
  virtualisation.oci-containers.backend = "podman";
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # GPU access in containers (nvidia-container-toolkit) is hardware-specific
  # and lives in the host's hardware.nix, not here.
}
