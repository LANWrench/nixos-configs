{ config, pkgs, ... }:

{
  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # D-Bus (required by most services and desktop environments)
  services.dbus.enable = true;

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
