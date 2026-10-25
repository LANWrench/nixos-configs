{
  pkgs,
  inputs,
  ...
}:

# CLI tooling shared by all hosts. Hosts can override packages
# (e.g. programs.btop.package with CUDA support on Nvidia machines).
{
  # System packages (desktop-agnostic, WSL-safe)
  environment.systemPackages = with pkgs; [
    tree
    vim
    wget
    git
    curl
    keyutils
    ripgrep
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    fuse
    jq
    dig
    ncdu
    restic
    openssl
  ];

  # User programs (home-manager)
  home-manager.users.michael = {
    programs.tmux.enable = true;

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    programs.btop.enable = true;

    programs.claude-code.enable = true;
    programs.opencode.enable = true;
  };
}
