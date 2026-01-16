{ config, pkgs, ... }:

{
  # KDE Plasma home configuration
  # Plasma provides its own terminal, app launcher, file manager, etc.

  # KDE-specific home packages (if any needed)
  home.packages = with pkgs; [
    # Add KDE-specific user packages here
  ];

  # KDE Power Management - disable auto screen-off and suspend
  home.file.".config/powerdevilrc".text = ''
    [AC][SuspendSession]
    idleTime=0
    suspendThenHibernate=false

    [Battery][SuspendSession]
    idleTime=0
    suspendThenHibernate=false

    [AC][DPMSControl]
    idleTime=0

    [Battery][DPMSControl]
    idleTime=0

    [AC][DimDisplay]
    idleTime=0

    [Battery][DimDisplay]
    idleTime=0
  '';

  # Basic Plasma shell configuration
  home.file.".config/plasmarc".text = ''
    [General]
  '';
}
