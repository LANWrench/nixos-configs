{ config, pkgs, ... }:

{
  # OCI containers with Podman
  virtualisation.oci-containers.backend = "podman";
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # CDI for GPU access in containers
  hardware.nvidia-container-toolkit.enable = true;
}
