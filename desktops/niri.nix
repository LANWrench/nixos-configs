{ config, pkgs, inputs, ... }:

{
  imports = [ ./fonts.nix ]; # Fonts shared by every desktop

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

  # ===== User side (home-manager) =====
  home-manager.users.michael = {
    # Shell UI (notifications, lock screen, idle management, launcher, polkit
    # auth prompts, OSD) is provided by Dank Material Shell — see
    # the system side above. Do not add standalone daemons for these here: a second
    # notification daemon races DMS for the org.freedesktop.Notifications D-Bus
    # name, and a second polkit agent causes doubled auth prompts.

    # Cohesive dark theming for the niri session (catppuccin-mocha via Stylix).
    # The Stylix module is imported HERE, not for every host: hosts without a
    # desktop (WSL) never load it. Stylix's overlays are incompatible with
    # home-manager.useGlobalPkgs unless stylix is enabled, which it only is here.
    imports = [ inputs.stylix.homeModules.stylix ];

    stylix = {
      enable = true;
      autoEnable = false; # allowlist targets; don't touch neovim/fish/btop/etc.
      polarity = "dark"; # default is "either"; needed for foot/qt dark variants
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.meslo-lg;
          name = "MesloLGS Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        sizes = {
          terminal = 12;
          popups = 18;
          applications = 12; # gtk.font + qtct font size; keeps portal dialogs sane
        };
      };

      cursor = {
        package = pkgs.hackneyed; # -> home.pointerCursor (XCURSOR_* env + gtk cursorTheme)
        name = "Hackneyed";
        size = 36;
      };

      targets = {
        gtk.enable = true; # adw-gtk3 + base16 gtk.css for gtk3/gtk4
        qt = {
          enable = true; # qtct + kvantum with base16 palette
          standardDialogs = "xdgdesktopportal"; # Qt apps use the same GTK portal file picker
        };
        "font-packages".enable = true; # install the font packages declared above
        foot.enable = true; # merges cleanly with existing pad setting
        neovim.enable = true; # base16 catppuccin-mocha colorscheme for nvim
      };
    };

    # Stylix's gtk target does NOT write the freedesktop dark preference; its gnome
    # target does but drags in GNOME Shell extensions/autostart. xdg-desktop-portal-gtk
    # serves these gsettings to GTK apps (dialogs, file picker), so set them directly.
    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-name = "DejaVu Sans 12";
      monospace-font-name = "MesloLGS Nerd Font Mono 14";
      icon-theme = "kora"; # kora-icon-theme (hosts/<name>/apps.nix); Stylix themes GTK colors but not icons
      cursor-theme = "Hackneyed";
      cursor-size = 36;
    };

    # Niri-specific user services
    services.kanshi.enable = true; # Display configuration

    # Terminal (Stylix-themed)
    programs.foot = {
      enable = true;
      settings = {
        main = {
          pad = "10x10"; # Add padding around terminal content
        };
      };
    };
  };
}
