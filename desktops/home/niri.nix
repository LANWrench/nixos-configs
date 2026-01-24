{ config, pkgs, ... }:

{
  # Dank Material Shell
  programs.dms-shell = {
    enable = true;
    systemd.enable = true;  # Auto-start via systemd
  };

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

  # Niri-specific user services
  services.mako.enable = true;      # Notification daemon
  services.kanshi.enable = true;    # Display configuration

  # Niri-specific programs
  programs.fuzzel.enable = true;    # Application launcher
  programs.foot.enable = true;      # Terminal emulator
  programs.rofi.enable = true;      # Alternative launcher

  # Niri-specific home packages
  home.packages = with pkgs; [
    mate.mate-polkit
  ];
}
