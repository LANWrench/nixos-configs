# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ./programs.nix
    ];

########################################
#### SYSTEM ####
########################################

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  system.stateVersion = "25.05"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

########################################
#### SERVICES ####
########################################

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  services.getty.autologinUser = "michael";

########################################
#### NETWORKING ####
########################################
  networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

########################################
#### USERS ####
########################################

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.michael= {
    isNormalUser = true;
    extraGroups = [ 
    	"wheel"
    	"networkmanager" 
    ]; 
  };
}