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

}