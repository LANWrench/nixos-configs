{ pkgs, ... }:

{

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
	waybar
	git
	hyprpaper
    fzf

    brave
  ];

  programs.kitty.enable = true;
  programs.hyprland.enable = true;

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