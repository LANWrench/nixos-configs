{ pkgs, ... }:

# Fonts for any machine with a screen. Imported by the desktop (niri/), so a
# host gets them by picking a desktop — not by being physical (a VM with a
# desktop needs them; a headless box or WSL does not). Any future desktop file
# should import this too.
{
  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.caskaydia-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
    nerd-fonts.blex-mono
    nerd-fonts.meslo-lg
    nerd-fonts.roboto-mono
    ibm-plex
    noto-fonts
    corefonts
    vista-fonts
  ];
}
