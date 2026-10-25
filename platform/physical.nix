{ config, pkgs, ... }:

# Platform: physical machines (desktops, laptops) with real hardware.
# WSL and headless hosts must NOT import this — they get networking,
# audio, and printing from their platform.

{
  # Tools for managing physical disks
  environment.systemPackages = with pkgs; [
    gparted
  ];

  # Networking
  networking.networkmanager.enable = true;
  # The networkmanager group only exists on hosts with NetworkManager, so
  # membership lives here, not in common/user.nix (same pattern as
  # libvirtd in features/virtualization.nix)
  users.users.michael.extraGroups = [ "networkmanager" ];

  # Audio with PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing
  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
    ];
  };

  # Printer discovery via Avahi
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
