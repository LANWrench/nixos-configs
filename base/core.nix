{ config, pkgs, inputs, ... }:

{
  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Common system packages (desktop-agnostic)
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    keyutils
    gparted
    ripgrep
    inputs.agenix.packages."x86_64-linux".default
    fuse
  ];

  # Fonts (shared across all systems)
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

  # D-Bus (required for most desktop environments)
  services.dbus.enable = true;
}
