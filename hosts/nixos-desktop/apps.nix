{
  pkgs,
  pkgs-stable,
  ...
}:

# This machine's user apps and their settings (home-manager).
{
  # Function form: `config` here is home-manager's (secret paths, home dir).
  home-manager.users.michael = { config, ... }: {
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

      # AI
      # unstable, not stable: 26.05 froze lmstudio at 0.4.15; unstable tracks
      # upstream releases. Swapped 2026-10-11.
      lmstudio

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
      # nordic + orchis-theme dropped 2026-08-01: both removed upstream (depended on
      # gtk-engine-murrine / GTK2). Unused here — niri themes via Stylix
      # catppuccin-mocha, not these GTK themes.
      hackneyed
      kora-icon-theme
      reversal-icon-theme
    ];

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
      agent = {
        build = {
          model = "litellm/smart-deepseek-v4-pro";
          permission = {
            edit = "allow";
            bash = "allow";
          };
        };
        plan = {
          model = "litellm/oracle-gpt-5.6-sol";
          permission = {
            edit = "deny";
            bash = "ask";
          };
        };
        chat = {
          model = "litellm/chat-deepseek-flash";
          permission = {
            edit = "deny";
            bash = "deny";
          };
        };
      };
      # Default stays a local model (no cloud cost); switch with /models in the TUI.
      # Must be one of the model_names LiteLLM exposes (see app01 litellmConfig).
      model = "litellm/fast-qwen-27b";
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
  };
}
