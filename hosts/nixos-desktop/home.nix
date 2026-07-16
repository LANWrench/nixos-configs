{
  config,
  pkgs,
  pkgs-stable,
  ...
}:

{
  imports = [
    # Shared home base (shell, starship, neovim, git, CLI tools)
    ../../home

    # Desktop environment (host-specific choice)
    ../../desktops/home/niri.nix
  ];

  # Home Manager configuration
  home.username = "michael";
  home.homeDirectory = "/home/michael";
  home.stateVersion = "25.05";

  # Theming: COSMIC themes itself. Stylix theming for the niri desktop
  # lives in desktops/home/niri.nix and activates only when niri is imported.

  # Host-specific packages
  home.packages = with pkgs; [
    # Browsers and communication
    brave
    pkgs-stable.discord # Use stable to avoid Electron build issues
    pkgs-stable.mailspring # Use stable to avoid Electron build issues

    # File managers and utilities
    peazip
    pkgs-stable.kdePackages.k3b
    cryptomator

    # Productivity
    pkgs-stable.logseq # Use stable to avoid Electron build issues
    pkgs-stable.obsidian # Use stable to avoid Electron build issues

    # Media
    vlc

    # Gaming (desktop-specific)
    steam
    pcsx2
    pkgs-stable.mudlet
    moonlight-qt

    # AI
    pkgs-stable.lmstudio # Use stable to avoid Electron build issues

    # Utilities
    localsend
    gnome-calculator
    teamviewer
    qbittorrent

    # Container tools
    distrobox

    # Infrastructure tools
    azure-storage-azcopy
    terraform
    opentofu
    colmena
    kubectl
    azure-cli
    dotnet-sdk

    # BTRFS Tools
    btrfs-assistant

    # Themes and icons
    nordic
    orchis-theme
    hackneyed
    kora-icon-theme
    reversal-icon-theme
  ];

  # CUDA-enabled btop on this Nvidia host (base enables programs.btop)
  programs.btop.package = pkgs.btop.override { cudaSupport = true; };

  # Show system health status on new terminals (features/terminal-status-banner.nix)
  programs.bash.initExtra = ''
    nixos-health
  '';
  programs.fish.interactiveShellInit = ''
    nixos-health

    bind \cy accept-autosuggestion
  '';

  # Services
  services.podman.enable = true;

  # Programs
  programs.onlyoffice.enable = true;

  programs.obs-studio = {
    enable = true;
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-pipewire-audio-capture
      obs-backgroundremoval
    ];
  };

  programs.vscode = {
    enable = true;
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        hashicorp.terraform
        ms-azuretools.vscode-bicep
        ms-dotnettools.vscode-dotnet-runtime
      ];
      userSettings = {
        "dotnetAcquisitionExtension.sharedExistingDotnetPath" = "/etc/profiles/per-user/michael/bin/dotnet";
        "dotnetAcquisitionExtension.allowInvalidPaths" = true;
      };
    };
  };
}
