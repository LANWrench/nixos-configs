{ config, pkgs, ... }:

{
  # Enable Niri window manager
  programs.niri.enable = true;

  # Dank Material Shell
  programs.dms-shell = {
    enable = true;
    systemd.enable = true;  # Auto-start via systemd
  };

  # Display Manager (GDM with Wayland support)
  services.displayManager = {
    autoLogin = {
      enable = false;
      user = "michael";
    };

    # GDM is Wayland-only as of GNOME 50; the old `wayland` option was removed
    gdm.enable = true;
  };

  # Enable X server with nvidia drivers (needed for some compatibility)
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };

  # XDG Desktop Portals for Niri
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
        "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
      };
    };
  };

  # Niri-specific system packages
  environment.systemPackages = with pkgs; [
    alacritty       # Terminal emulator
    swaylock        # Screen locker
    mako            # Notification daemon
    swayidle        # Idle management
    xwayland-satellite  # XWayland support for legacy apps
  ];

  # Services needed for Niri
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;
  programs.dconf.enable = true;

  # Enable common services for desktop
  services.udisks2.enable = true;
  services.gvfs.enable = true;
}
