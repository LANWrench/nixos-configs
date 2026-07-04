{ config, pkgs, ... }:

{
  # User account
  users.users.michael = {
    isNormalUser = true;
    # libvirtd group is added by features/virtualization.nix on hosts that use it
    extraGroups = [ "wheel" "networkmanager" "video" "cdrom" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      # "public-key-goes-here"
    ];
  };

  # Enable fish shell system-wide
  programs.fish.enable = true;
}
