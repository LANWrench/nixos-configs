{ config, pkgs, ... }:

{
  # GNOME Desktop home configuration with PaperWM
  # PaperWM provides horizontal scrollable tiling similar to niri

  # GNOME-specific home packages
  home.packages = with pkgs; [
    gnomeExtensions.paperwm
    gnome-screenshot  # For screenshot keybindings
  ];

  dconf.settings = {
    # ========================================
    # ENABLE GNOME EXTENSIONS
    # ========================================
    "org/gnome/shell" = {
      enabled-extensions = [
        "paperwm@paperwm.github.com"
      ];
    };

    # ========================================
    # POWER MANAGEMENT
    # ========================================
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
      idle-dim = false;
    };
    "org/gnome/desktop/session" = {
      idle-delay = 0;
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
      idle-activation-enabled = false;
    };

    # ========================================
    # PAPERWM SETTINGS
    # ========================================
    "org/gnome/shell/extensions/paperwm" = {
      # Window gaps (matching niri's 16px gaps)
      window-gap = 16;

      # Horizontal and vertical margins
      horizontal-margin = 0;
      vertical-margin = 0;

      # Animation settings
      animation-time = 0.15;

      # Disable top bar features to match niri's minimal approach
      show-workspace-indicator = true;
      show-window-position-bar = true;
    };

    # ========================================
    # PAPERWM KEYBINDINGS (matching niri)
    # ========================================
    "org/gnome/shell/extensions/paperwm/keybindings" = {
      # Close window - Mod+Q (matching niri)
      close-window = ["<Super>q"];

      # Focus navigation - Mod+H/J/K/L (matching niri)
      switch-left = ["<Super>h" "<Super>Left"];
      switch-right = ["<Super>l" "<Super>Right"];
      switch-up = ["<Super>k" "<Super>Up"];
      switch-down = ["<Super>j" "<Super>Down"];

      # Move windows - Mod+Ctrl+H/J/K/L (matching niri)
      move-left = ["<Super><Control>h" "<Super><Control>Left"];
      move-right = ["<Super><Control>l" "<Super><Control>Right"];
      move-up = ["<Super><Control>k" "<Super><Control>Up"];
      move-down = ["<Super><Control>j" "<Super><Control>Down"];

      # Move to monitor - Mod+Shift+Ctrl+H/J/K/L (matching niri)
      move-monitor-left = ["<Super><Shift><Control>h" "<Super><Shift><Control>Left"];
      move-monitor-right = ["<Super><Shift><Control>l" "<Super><Shift><Control>Right"];
      move-monitor-above = ["<Super><Shift><Control>k" "<Super><Shift><Control>Up"];
      move-monitor-below = ["<Super><Shift><Control>j" "<Super><Shift><Control>Down"];

      # Switch to first/last window - Mod+Home/End (matching niri)
      switch-first = ["<Super>Home"];
      switch-last = ["<Super>End"];

      # Resize windows - Mod+Minus/Equal (matching niri)
      resize-h-dec = ["<Super>minus"];
      resize-h-inc = ["<Super>equal"];
      resize-v-dec = ["<Super><Shift>minus"];
      resize-v-inc = ["<Super><Shift>equal"];

      # Center window - Mod+C (matching niri)
      center-horizontally = ["<Super>c"];

      # Take/untake window - Mod+BracketLeft/Right (similar to niri's consume/expel)
      take-window = ["<Super>bracketright"];
      untake-window = ["<Super>bracketleft"];

      # Fullscreen - Mod+Shift+F (matching niri)
      toggle-maximize-width = ["<Super>f"];

      # New window - Mod+Return (disabled, using custom keybinding for terminal)
      new-window = [];

      # Cycle width presets - Mod+R (matching niri)
      cycle-width = ["<Super>r"];
      cycle-width-backwards = ["<Super><Shift>r"];

      # Cycle height - Mod+Shift+R (matching niri)
      cycle-height = ["<Super><Control>r"];

      # Toggle scratch - useful workspace
      toggle-scratch-layer = ["<Super>Escape"];

      # Live alt-tab
      live-alt-tab = ["<Super>Tab"];
      live-alt-tab-backward = ["<Super><Shift>Tab"];
    };

    # ========================================
    # GNOME WM KEYBINDINGS
    # ========================================
    "org/gnome/desktop/wm/keybindings" = {
      # Fullscreen - Mod+Shift+F (matching niri)
      toggle-fullscreen = ["<Super><Shift>f"];

      # Workspace switching - Mod+1-9 (matching niri)
      switch-to-workspace-1 = ["<Super>1"];
      switch-to-workspace-2 = ["<Super>2"];
      switch-to-workspace-3 = ["<Super>3"];
      switch-to-workspace-4 = ["<Super>4"];
      switch-to-workspace-5 = ["<Super>5"];
      switch-to-workspace-6 = ["<Super>6"];
      switch-to-workspace-7 = ["<Super>7"];
      switch-to-workspace-8 = ["<Super>8"];
      switch-to-workspace-9 = ["<Super>9"];

      # Move window to workspace - Mod+Ctrl+1-9 (matching niri)
      move-to-workspace-1 = ["<Super><Control>1"];
      move-to-workspace-2 = ["<Super><Control>2"];
      move-to-workspace-3 = ["<Super><Control>3"];
      move-to-workspace-4 = ["<Super><Control>4"];
      move-to-workspace-5 = ["<Super><Control>5"];
      move-to-workspace-6 = ["<Super><Control>6"];
      move-to-workspace-7 = ["<Super><Control>7"];
      move-to-workspace-8 = ["<Super><Control>8"];
      move-to-workspace-9 = ["<Super><Control>9"];

      # Workspace navigation - Mod+U/I (matching niri)
      switch-to-workspace-up = ["<Super>i" "<Super>Page_Up"];
      switch-to-workspace-down = ["<Super>u" "<Super>Page_Down"];

      # Move window to workspace up/down - Mod+Ctrl+U/I (matching niri)
      move-to-workspace-up = ["<Super><Control>i" "<Super><Control>Page_Up"];
      move-to-workspace-down = ["<Super><Control>u" "<Super><Control>Page_Down"];

      # Disable conflicting defaults
      switch-applications = [];
      switch-applications-backward = [];
      panel-main-menu = [];

      # Keep standard Alt+Tab for window switching
      switch-windows = ["<Alt>Tab"];
      switch-windows-backward = ["<Alt><Shift>Tab"];
    };

    # ========================================
    # GNOME SHELL KEYBINDINGS
    # ========================================
    "org/gnome/shell/keybindings" = {
      # Show overview - Mod+O (matching niri)
      toggle-overview = ["<Super>o"];

      # Disable conflicting defaults
      toggle-application-view = [];
      toggle-message-tray = [];
    };

    # ========================================
    # MEDIA KEYS & CUSTOM KEYBINDINGS
    # ========================================
    "org/gnome/settings-daemon/plugins/media-keys" = {
      # Home folder - Mod+E (matching niri)
      home = ["<Super>e"];

      # Browser - Mod+B (matching niri)
      www = ["<Super>b"];

      # Screen lock - Super+Alt+L (matching niri)
      screensaver = ["<Super><Alt>l"];

      # Logout - Mod+Shift+E (matching niri)
      logout = ["<Super><Shift>e"];

      # Screenshots - disable defaults, we'll use custom
      screenshot = [];
      screenshot-window = [];
      area-screenshot = [];

      # Custom keybindings list
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
      ];
    };

    # ========================================
    # CUSTOM KEYBINDINGS
    # ========================================

    # Custom 0: App Launcher - Mod+Space (matching niri's fuzzel)
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>space";
      command = "fuzzel";
      name = "App Launcher - Fuzzel";
    };

    # Custom 1: Screenshot (full) - Print (matching niri)
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "Print";
      command = "gnome-screenshot";
      name = "Screenshot";
    };

    # Custom 2: Screenshot screen - Ctrl+Print (matching niri)
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      binding = "<Control>Print";
      command = "gnome-screenshot --display";
      name = "Screenshot Screen";
    };

    # Custom 3: Screenshot window - Alt+Print (matching niri)
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      binding = "<Alt>Print";
      command = "gnome-screenshot --window";
      name = "Screenshot Window";
    };

    # Custom 4: Terminal - Super+Return
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      binding = "<Super>Return";
      command = "kgx";
      name = "Terminal";
    };

    # ========================================
    # MUTTER SETTINGS
    # ========================================
    "org/gnome/mutter" = {
      # Dynamic workspaces (similar to niri)
      dynamic-workspaces = true;

      # Let PaperWM handle window positioning
      center-new-windows = false;
    };
  };
}
