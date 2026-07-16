{ config, pkgs, ... }:

{
  # Enable Niri window manager
  programs.niri.enable = true;

  # Dank Material Shell
  programs.dms-shell = {
    enable = true;
    systemd.enable = true;  # Auto-start via systemd
  };

  # DMS Material greeter (greetd-based) — matches the DMS shell for a
  # cohesive login screen. Rollback: previous generation from boot menu.
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
  };

  # Enable X server (needed for some compatibility).
  # GPU drivers (videoDrivers) are hardware-specific → hosts/<name>/hardware.nix
  services.xserver.enable = true;

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

  # Niri-specific system packages.
  # NOTE: DMS provides notifications, lock screen, idle management, launcher,
  # and the polkit agent — do not add mako/swaylock/swayidle/fuzzel here
  # (a second notification daemon conflicts on the D-Bus name).
  environment.systemPackages = with pkgs; [
    xwayland-satellite  # XWayland support for legacy apps
    nautilus  # GNOME Files — file manager (niri ships none; uses the gvfs backend below)
  ];

  # Services needed for Niri
  services.gnome.gnome-keyring.enable = true;
  # Unlock the keyring with the login password at the greetd (DMS greeter)
  # login — without this a stray "unlock keyring" dialog appears after login
  security.pam.services.greetd.enableGnomeKeyring = true;
  programs.dconf.enable = true;

  # Enable common services for desktop
  services.udisks2.enable = true;
  services.gvfs.enable = true;
}
