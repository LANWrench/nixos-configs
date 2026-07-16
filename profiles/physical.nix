{ config, pkgs, ... }:

# Profile for physical machines (desktops, laptops) with real hardware.
# WSL and headless hosts must NOT import this — they get networking,
# audio, and printing from their platform.

{
  # Tools for managing physical disks
  environment.systemPackages = with pkgs; [
    gparted
  ];

  # Fonts (only matter where a display is attached; WSL uses Windows fonts)
  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.caskaydia-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
    nerd-fonts.blex-mono
    nerd-fonts.meslo-lg
    nerd-fonts.roboto-mono
    ibm-plex
    noto-fonts
    corefonts
    vista-fonts
  ];

  # Networking
  networking.networkmanager.enable = true;
  # The networkmanager group only exists on hosts with NetworkManager, so
  # membership lives here, not in users/michael.nix (same pattern as
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
