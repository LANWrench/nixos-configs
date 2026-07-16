{ config, pkgs, ... }:

{
  # Enable COSMIC Desktop Environment
  services.desktopManager.cosmic.enable = true;

  # Display Manager (COSMIC Greeter)
  services.displayManager = {
    cosmic-greeter = {
      enable = true;
    };
  };

  # Enable X server.
  # GPU drivers (videoDrivers) are hardware-specific → hosts/<name>/hardware.nix
  services.xserver.enable = true;

  # XDG Desktop Portals for COSMIC
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config = {
      common = {
        default = ["gtk"];
      };
      cosmic = {
        default = ["cosmic" "gtk"];
      };
    };
  };

  # COSMIC provides most tools built-in, but you might want some extras
  environment.systemPackages = with pkgs; [
    # Add COSMIC-specific tools here if needed
  ];

  # Services needed for COSMIC
  programs.dconf.enable = true;
  security.polkit.enable = true;

  # Enable common services for desktop
  services.udisks2.enable = true;
  services.gvfs.enable = true;
}
