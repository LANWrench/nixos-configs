{ config, pkgs, ... }:

{
  # COSMIC Desktop home configuration
  # COSMIC provides its own terminal, app launcher, file manager, etc.
  # Services/programs are disabled by default, so we only need to enable what we want

  # COSMIC-specific home packages (if any needed)
  home.packages = with pkgs; [
    # Add COSMIC-specific user packages here
  ];

  # COSMIC uses files to configure settings
  home.file.".config/cosmic/com.system76.CosmicIdle/v1/screen_off_time".text = "None";
  home.file.".config/cosmic/com.system76.CosmicIdle/v1/suspend_on_ac_time".text = "None";

  home.file.".config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".text = ''
    {
        (modifiers: [Super], key: "Print"): Disable,
        (modifiers: [Super], key: "t"): Disable,
        (modifiers: [], key: "Print"): System(Screenshot),
        (modifiers: [Super], key: "Return"): System(Terminal),
        (modifiers: [Super], key: "F11"): Disable,
        (modifiers: [Super], key: "f"): Fullscreen,
        (modifiers: [Super], key: "e"): System(HomeFolder),
        (modifiers: [Super], key: "Tab"): NextWorkspace,
        (modifiers: [Super, Shift], key: "Tab"): PreviousWorkspace,
    }
  '';

}