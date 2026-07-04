{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = { };
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting
    '';
  };
}
