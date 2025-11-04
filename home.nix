{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "michael";
  home.homeDirectory = "/home/michael";
  home.stateVersion = "25.05";

  # catppuccin = {
  #   enable = true;
  #   flavor = "mocha";

  #   hyprland.enable = true;
  #   kitty.enable = true;
  #   nvim.enable = true;
  #   waybar.enable = true;
  #   brave.enable = true;
  #   btop.enable = true;
  # };

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
    # catppuccin-gtk
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

  programs.waybar = {
    enable = true;
    systemd.enable = true; # makes it start with your session
  };

  programs.kitty = {
    enable = true;
    font.name = "JetBrainsMono Nerd Font";
    font.size = 12;

    # Optional: keep your own overrides cleanly layered
    extraConfig = ''
      # You can still add custom lines here if you want
      map ctrl+shift+t new_tab
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