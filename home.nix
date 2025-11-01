{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "michael";
  home.homeDirectory = "/home/michael";
  home.stateVersion = "25.05";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    brave
    discord
    btop
    kdePackages.dolphin
];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
      enable = true;
      userEmail = "5728708+LANWrench@users.noreply.github.com";
      userName = "Michael";
  };
  programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
      extraConfig = ''
      filetype plugin indent on
      set expandtab
      set shiftwidth=2
      set softtabstop=2
      set tabstop=2
      set number
      set relativenumber
      set smartindent
      set showmatch
      set backspace=indent,eol,start
      syntax on
      '';
    };
}