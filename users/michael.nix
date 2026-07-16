{ config, pkgs, ... }:

{
  # User account
  users.users.michael = {
    isNormalUser = true;
    # Groups tied to a profile/feature are added by that module (NixOS merges
    # the lists): networkmanager by profiles/physical.nix, libvirtd by
    # features/virtualization.nix.
    extraGroups = [ "wheel" "video" "cdrom" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      # "public-key-goes-here"
    ];
  };

  # Enable fish shell system-wide
  programs.fish.enable = true;
}
