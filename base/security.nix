{ config, pkgs, ... }:

{
  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Security
  security.polkit.enable = true;
  security.rtkit.enable = true;

  # Allow users to read FUSE mounts
  programs.fuse.userAllowOther = true;
}
