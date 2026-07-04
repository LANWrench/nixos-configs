{ config, pkgs, ... }:

# Git identity — defined once, inherited by every host.
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Michael";
      user.email = "5728708+LANWrench@users.noreply.github.com";
      init.defaultBranch = "main";
    };
  };
}
