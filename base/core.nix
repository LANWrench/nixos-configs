{ config, pkgs, inputs, ... }:

{
  # Common system packages (desktop-agnostic, WSL-safe)
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    keyutils
    ripgrep
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    fuse
  ];

  # D-Bus (required by most services and desktop environments)
  services.dbus.enable = true;
}
