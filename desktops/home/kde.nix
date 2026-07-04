{ config, pkgs, lib, ... }:

let
  kwrite = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6";
  tab = "\t";
in
{
  # KDE Plasma home configuration
  # Plasma provides its own terminal, app launcher, file manager, etc.

  home.packages = with pkgs; [
    kdePackages.karousel
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

  home.activation.setKDEConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Dark theme (Breeze Dark look-and-feel)
    ${kwrite} --file kdeglobals --group General --key ColorScheme "BreezeDark"
    ${kwrite} --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

    # --- Remap conflicting KDE system shortcuts ---

    # Lock screen: Meta+L → Meta+Alt+L (matches niri's Super+Alt+L)
    ${kwrite} --file kglobalshortcutsrc --group ksmserver --key "Lock Session" "Meta+Alt+L,Screensaver,Lock Session"

    # Free Meta+Q from activity switcher (want it for close window)
    ${kwrite} --file kglobalshortcutsrc --group plasmashell --key "manage activities" "none,Meta+Q,Show Activity Switcher"

    # Free Meta+V from clipboard popup (want it for Karousel float toggle)
    ${kwrite} --file kglobalshortcutsrc --group plasmashell --key "show-on-mouse-pos" "none,Meta+V,Show Clipboard Items at Mouse Position"

    # KWin: add Meta+Q for close window (matches niri's Mod+Q)
    ${kwrite} --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Q${tab}Alt+F4,Alt+F4,Close Window"

    # KWin: add Meta+F for maximize (matches niri's Mod+F)
    ${kwrite} --file kglobalshortcutsrc --group kwin --key "Window Maximize" "Meta+F${tab}Meta+PgUp,Meta+PgUp,Maximize Window"

    # KWin: add Meta+Shift+F for fullscreen (matches niri's Mod+Shift+F)
    ${kwrite} --file kglobalshortcutsrc --group kwin --key "Window Fullscreen" "Meta+Shift+F,none,Make Window Fullscreen"

    # --- Karousel: vim-style HJKL navigation (replaces WASD) ---
    # After this change Meta+W (Overview) and Meta+D (Show Desktop) are free of conflicts.

    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-focus-left" "Meta+H,none,Karousel: Move focus left"
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-focus-down" "Meta+J,none,Karousel: Move focus down"
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-focus-up" "Meta+K,none,Karousel: Move focus up"
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-focus-right" "Meta+L,none,Karousel: Move focus right"

    # Karousel: Ctrl+HJKL to move column/window (matches niri's Mod+Ctrl+H/J/K/L)
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-column-move-left" "Meta+Ctrl+H,none,Karousel: Move column left"
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-column-move-right" "Meta+Ctrl+L,none,Karousel: Move column right"
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-window-move-down" "Meta+Ctrl+J,none,Karousel: Move window down"
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-window-move-up" "Meta+Ctrl+K,none,Karousel: Move window up"

    # Karousel: Meta+[/] to move window between columns (matches niri's Mod+BracketLeft/Right)
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-window-move-left" "Meta+bracketleft,none,Karousel: Move window left"
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-window-move-right" "Meta+bracketright,none,Karousel: Move window right"

    # Karousel: Meta+V for float toggle (matches niri's Mod+V)
    ${kwrite} --file kglobalshortcutsrc --group karousel --key "karousel-window-toggle-floating" "Meta+V,none,Karousel: Toggle floating"

    # --- Application launchers (matches niri's Mod+Return / Mod+B) ---

    # Free Meta+B from powerdevil's "Switch Power Profile" before reassigning
    ${kwrite} --file kglobalshortcutsrc --group org_kde_powerdevil --key "powerProfile" "Battery,Battery,Switch Power Profile"

    # Meta+Return: open Konsole terminal
    ${kwrite} --file kglobalshortcutsrc --group "org.kde.konsole.desktop" --key "_launch" "Meta+Return,none,Konsole"

    # Meta+B: open Brave browser
    ${kwrite} --file kglobalshortcutsrc --group "brave-browser.desktop" --key "_launch" "Meta+B,none,Brave Web Browser"
  '';
}
