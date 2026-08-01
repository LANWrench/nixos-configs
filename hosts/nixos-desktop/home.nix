{
  config,
  pkgs,
  pkgs-stable,
  inputs,
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

  # Decrypt to a fixed absolute path. The home-manager agenix module otherwise
  # decrypts under ${XDG_RUNTIME_DIR}, and that literal string ends up in
  # opencode's JSON config — opencode does NOT expand env vars in {file:...}
  # paths (verified against opencode 1.18.3), so it must be a plain path.
  age.secrets."opencode-env" = {
    file = ../../secrets/opencode-env.age;
    path = "${config.home.homeDirectory}/.config/agenix/opencode-env";
  };

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
    # logseq dropped 2026-07-20: stuck on EOL electron-39.8.10 (marked insecure)
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
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default # Agent CLI; uses local llama-server (features/llama-cpp.nix)

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

  # opencode pointed at the fleet LiteLLM gateway (llm.handmc.net → app01:4000).
  # The opencode-plugin-litellm plugin queries the proxy's /v1/models at startup
  # and registers every model automatically — so the model list lives ONLY in
  # LiteLLM's config.yaml. Add a model there and it shows up here on next launch;
  # nothing to maintain in this file. The plugin is auto-installed by opencode into
  # ~/.config/opencode/node_modules (not managed here).
  #
  # The provider block is still required because our proxy is remote (the plugin's
  # auto-detect only probes localhost). The API key is a LiteLLM key (master or a
  # minted virtual key) via LITELLM_API_KEY — never hardcoded (it would land in the
  # world-readable Nix store).
  programs.opencode.settings = {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ "opencode-plugin-litellm@latest" ];
    provider.litellm = {
      npm = "@ai-sdk/openai-compatible";
      name = "Fleet LiteLLM";
      options = {
        baseURL = "https://llm.handmc.net/v1";
        # opencode's {file:...} inlines the file's raw contents (trailing newline
        # trimmed) as the key, so opencode-env.age must hold ONLY the bare key.
        apiKey = "{file:${config.age.secrets."opencode-env".path}}";
      };
    };
    # Default stays a local model (no cloud cost); switch with /models in the TUI.
    # Must be one of the model_names LiteLLM exposes (fast = local Qwen 27B).
    model = "litellm/fast";
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
