{ config, pkgs, ... }:

# CLI tooling shared by all hosts. Hosts can override packages
# (e.g. programs.btop.package with CUDA support on Nvidia machines).
{
  programs.tmux.enable = true;

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.btop.enable = true;

  programs.htop.enable = true;

  programs.claude-code.enable = true;
}
