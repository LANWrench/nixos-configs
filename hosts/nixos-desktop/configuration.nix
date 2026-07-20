{ config, pkgs, ... }:

{
  # Host-specific settings (hostname is set by mkHost in lib/mkhost.nix)
  time.timeZone = "America/Chicago";

  # Firewall ports for host-specific services
  networking.firewall.allowedTCPPorts = [
    53317 # LocalSend
    5173 # npm tubtrack test site
  ];

  # Binary cache for CUDA packages (this host builds ollama-cuda etc. weekly
  # via auto-update; CUDA is unfree so cache.nixos.org never has it).
  # `extra-` appends to the defaults instead of replacing them.
  nix.settings = {
    extra-substituters = [ "https://cuda-maintainers.cachix.org" ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
}
