{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "michael";
  home.homeDirectory = "/home/michael";
  home.stateVersion = "25.05";

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    brave
    discord
    btop
    nemo
    localsend
    vscode
    steam

    # Themes and icons
    nordic # gtk and kde theme
    orchis-theme
    hackneyed # windows 3.x inspired cursor theme
    kora-icon-theme
    reversal-icon-theme
];

  services.walker = {
    enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

	programs.bash = {
		enable = true;
		shellAliases = {
			btw = "echo i use hyprland btw";
		};
		profileExtra = ''
         hyprland			
		'';
	};

  programs.git = {
      enable = true;
      settings = {
        user.name = "Michael";
        user.email = "5728708+LANWrench@users.noreply.github.com";
      };
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