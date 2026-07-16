{
  config,
  pkgs,
  pkgs-stable,
  ...
}:

{
  imports = [
    # Shared home base (shell, starship, neovim, git, CLI tools).
    # Identical shell/prompt/CLI experience as every other host.
    ../../home
    # No desktop home module — WSL has no local desktop.
  ];

  # Home Manager configuration
  home.username = "michael";
  home.homeDirectory = "/home/michael";
  home.stateVersion = "25.05";

  # Host-specific packages (work tooling goes here)
  home.packages = with pkgs; [
    # e.g. azure-cli, kubectl, terraform, gh — add what this work box needs
  ];
}
