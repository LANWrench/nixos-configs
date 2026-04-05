{ config, pkgs, lib, ... }:

{
  # Automatic system updates for flake-based configurations
  system.autoUpgrade = {
    enable = true;
    flake = "/home/michael/nix-config";
    flags = [
      "--recreate-lock-file"  # Update ALL inputs
      "--commit-lock-file"
      "-L" # print build logs
    ];
    dates = "weekly";
    randomizedDelaySec = "45min";
  };

  # Optional: Enable automatic garbage collection to clean old generations
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optional: Optimize nix store weekly
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
