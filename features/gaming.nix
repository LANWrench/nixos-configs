{ config, pkgs, ... }:

{
  # Gaming-specific system programs
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # Games and launchers (home-manager)
  home-manager.users.michael.home.packages = with pkgs; [
    steam
    pcsx2
    # unstable, not stable: 26.05 froze mudlet at 4.19.1 which fails to build;
    # unstable's 4.22.0 builds (and is cached). Swapped 2026-08-01.
    mudlet
    moonlight-qt
  ];
}
