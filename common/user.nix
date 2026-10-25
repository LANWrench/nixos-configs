{ config, pkgs, ... }:

{
  # User account
  users.users.michael = {
    isNormalUser = true;
    # Groups tied to a platform/feature are added by that module (NixOS merges
    # the lists): networkmanager by platform/physical.nix, libvirtd by
    # features/virtualization.nix.
    extraGroups = [ "wheel" "video" "cdrom" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      # "public-key-goes-here"
    ];
  };

  # Enable fish shell system-wide
  programs.fish.enable = true;

  # Home-manager basics for the same user. home.stateVersion is per machine
  # (frozen at install time), so each host sets it in hosts/<name>/default.nix.
  home-manager.users.michael = {
    home.username = "michael";
    home.homeDirectory = "/home/michael";

    home.sessionPath = [
      "$HOME/.local/bin"
    ];

    xdg.enable = true;

    programs.home-manager.enable = true;
  };
}
