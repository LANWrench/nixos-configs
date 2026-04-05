{ config, pkgs, pkgs-stable, ... }:

{
  imports = [
    # Home modules
    ./modules/neovim.nix
    ./modules/starship.nix

    # ========================================
    # DESKTOP ENVIRONMENT - Choose one below
    # ========================================
    # Comment out the one you're NOT using

    ./desktops/home/niri.nix
    # ./desktops/home/kde.nix
    # ./desktops/home/cosmic.nix
  ];

  # Home Manager configuration
  home.username = "michael";
  home.homeDirectory = "/home/michael";
  home.stateVersion = "25.05";

  xdg.enable = true;

  # Stylix theming
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    targets = {
      # neovim.enable = false;
      kde.enable = false;  # Disable Stylix for KDE - use native KDE theming
    };
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.meslo-lg;
        name = "MesloLGS Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      sizes = {
        terminal = 12;
        popups = 18;
      };
    };
    cursor = {
      package = pkgs.hackneyed;
      name = "Hackneyed";
      size = 36;
    };
  };

  # Common packages (desktop-agnostic)
  home.packages = with pkgs; [
    # Browsers and communication
    brave
    discord
    mailspring
    teamspeak3

    # File managers and utilities
    nemo
    peazip
    pkgs-stable.kdePackages.k3b

    # Productivity
    logseq
    obsidian

    # Media
    vlc

    # Gaming
    steam
    winboat
    pcsx2
    pkgs-stable.mudlet
    lutris
    r2modman
    nexusmods-app-unfree
    heroic

    # Utilities
    localsend
    gnome-calculator
    teamviewer
    qbittorrent

    # CLI Tools
    (btop.override { cudaSupport = true; })

    # Infrastructure tools
    azure-storage-azcopy
    terraform
    kubectl
    azure-cli
    dotnet-sdk
    dotnet-runtime

    # BTRFS Tools
    btrfs-assistant

    # Themes and icons
    nordic
    orchis-theme
    hackneyed
    kora-icon-theme
    reversal-icon-theme
  ];

  # Services (desktop-agnostic)
  services.podman.enable = true;

  # Programs (desktop-agnostic)
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = { };
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting
    '';
  };

  programs.starship.enable = true;
  programs.tmux.enable = true;

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Michael";
      user.email = "5728708+LANWrench@users.noreply.github.com";
      init.defaultBranch = "main";
    };
  };

  programs.claude-code.enable = true;
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
