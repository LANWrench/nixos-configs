{ config, pkgs, ... }:

{
  # Enable GNOME Desktop Environment
  services.desktopManager.gnome.enable = true;

  # Display Manager (GDM - GNOME's native display manager)
  services.displayManager = {
    gdm = {
      enable = true;
      wayland = true;
    };
    autoLogin = {
      enable = false;
    };
  };

  # Enable X server with nvidia drivers
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };

  # XDG Desktop Portals for GNOME
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = ["gnome" "gtk"];
      };
      gnome = {
        default = ["gnome" "gtk"];
        "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
        "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
      };
    };
  };

  # GNOME provides most tools built-in
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
  ];

  # Services needed for GNOME
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
  security.polkit.enable = true;

  # Enable common services for desktop
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Exclude some default GNOME apps (optional - customize as needed)
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany  # GNOME Web browser
    geary     # Email client
  ];
}
