{ pkgs, ... }:

{

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
	waybar
	hyprpaper
    fzf
    kitty
    impala # tui for managing wifi connections
    nwg-look
  ];

  programs.hyprland = {
	enable = true;
	xwayland.enable = true;
  };

  # User-specific configurations moved to home.nix
}