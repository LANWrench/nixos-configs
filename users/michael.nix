{ config, pkgs, ... }:

{
  # User account
  users.users.michael = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "cdrom" "libvirtd" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      # "public-key-goes-here"
    ];
  };

  # Enable fish shell system-wide
  programs.fish.enable = true;
}
