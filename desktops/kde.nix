{ config, pkgs, ... }:

{
  # Enable KDE Plasma 6 Desktop Environment
  services.desktopManager.plasma6.enable = true;

  # Display Manager (SDDM - KDE's native display manager)
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = false;  # Use X11 for NVIDIA compatibility
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

  # XDG Desktop Portals for KDE
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = ["kde" "gtk"];
      };
      plasma = {
        default = ["kde" "gtk"];
        "org.freedesktop.impl.portal.ScreenCast" = ["kde"];
        "org.freedesktop.impl.portal.Screenshot" = ["kde"];
      };
    };
  };

  # KDE Plasma provides most tools built-in
  environment.systemPackages = with pkgs; [
    # Add KDE-specific tools here if needed
  ];

  # Services needed for KDE
  programs.dconf.enable = true;
  security.polkit.enable = true;

  # Enable common services for desktop
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Power management - disable system-level auto actions
  # Let KDE handle power management through user settings
  services.logind = {
    lidSwitch = "ignore";
    powerButtonAction = "ignore";
  };
}
