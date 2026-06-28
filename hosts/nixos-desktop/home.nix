{ config, pkgs, pkgs-stable, ... }:

{
  imports = [
    # Home modules
    ../../modules/neovim.nix
    ../../modules/starship.nix

    # Desktop environment (host-specific choice)
    ../../desktops/home/gnome.nix
  ];

  # Home Manager configuration
  home.username = "michael";
  home.homeDirectory = "/home/michael";
  home.stateVersion = "25.05";
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  xdg.enable = true;

  # Stylix theming - disabled for GNOME desktop
  stylix = {
    enable = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    targets = {
      kde.enable = false;
      gnome.enable = false;
      gtk.enable = false;
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

  # Host-specific packages
  home.packages = with pkgs; [
    # Browsers and communication
    brave
    discord
    mailspring

    # File managers and utilities
    nemo
    peazip
    pkgs-stable.kdePackages.k3b
    cryptomator
    megasync
    pcloud

    # Productivity
    logseq
    obsidian

    # Media
    vlc

    # Gaming (desktop-specific)
    steam
    winboat
    pcsx2
    pkgs-stable.mudlet
    lutris
    r2modman
    nexusmods-app-unfree
    heroic
    moonlight-qt

    # AI
    lmstudio

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
    opentofu
    colmena
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

  # Services
  services.podman.enable = true;

  # Programs
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
    userName = "Michael";
    userEmail = "5728708+LANWrench@users.noreply.github.com";
    extraConfig = {
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
