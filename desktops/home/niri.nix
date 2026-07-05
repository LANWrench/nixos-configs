{ config, pkgs, ... }:

{
  # Polkit authentication agent
  systemd.user.services.polkit-mate = {
    Unit = {
      Description = "MATE Polkit Authentication Agent";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Cohesive dark theming for the niri session (catppuccin-mocha via Stylix).
  # Scoped here so COSMIC (which themes itself) is untouched — this module is
  # only imported when the host selects the niri desktop.
  stylix = {
    enable = true;
    autoEnable = false;          # allowlist targets; don't touch neovim/fish/btop/etc.
    polarity = "dark";           # default is "either"; needed for foot/qt dark variants
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
        applications = 12;       # gtk.font + qtct font size; keeps portal dialogs sane
      };
    };

    cursor = {
      package = pkgs.hackneyed;  # -> home.pointerCursor (XCURSOR_* env + gtk cursorTheme)
      name = "Hackneyed";
      size = 36;
    };

    targets = {
      gtk.enable = true;                      # adw-gtk3 + base16 gtk.css for gtk3/gtk4
      qt = {
        enable = true;                        # qtct + kvantum with base16 palette
        standardDialogs = "xdgdesktopportal"; # Qt apps use the same GTK portal file picker
      };
      "font-packages".enable = true;          # install the font packages declared above
      foot.enable = true;                     # merges cleanly with existing pad setting
      fuzzel.enable = true;
      mako.enable = true;
      rofi.enable = true;
    };
  };

  # Stylix's gtk target does NOT write the freedesktop dark preference; its gnome
  # target does but drags in GNOME Shell extensions/autostart. xdg-desktop-portal-gtk
  # serves these gsettings to GTK apps (dialogs, file picker), so set them directly.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    font-name = "DejaVu Sans 12";
    monospace-font-name = "MesloLGS Nerd Font Mono 12";
    cursor-theme = "Hackneyed";
    cursor-size = 36;
  };

  # Niri-specific user services
  services.mako.enable = true;      # Notification daemon
  services.kanshi.enable = true;    # Display configuration

  # Niri-specific programs
  programs.fuzzel.enable = true;    # Application launcher
  programs.foot = {
    enable = true;
    settings = {
      main = {
        pad = "10x10";              # Add padding around terminal content
      };
    };
  };
  programs.rofi.enable = true;      # Alternative launcher

  # Niri-specific home packages
  home.packages = with pkgs; [
    mate.mate-polkit
  ];
}
