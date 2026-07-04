{ config, pkgs, ... }:

# Shared home-manager base for ALL hosts (desktops, laptops, WSL).
# Rule: only things that make sense on a machine with no display belong here.
# Host-specific packages and programs go in hosts/<name>/home.nix.

{
  imports = [
    ./shell.nix
    ./starship.nix
    ./neovim.nix
    ./git.nix
    ./cli.nix
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  xdg.enable = true;

  programs.home-manager.enable = true;
}
