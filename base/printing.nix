{ config, pkgs, ... }:

{
  # Printing
  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
    ];
  };

  # Printer discovery via Avahi
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
