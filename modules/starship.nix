{ config, pkgs, lib, ... }:

{
  stylix.targets.starship.enable = false;
  
  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "$username"
        "@"
        "$hostname"
        ":"
        "$directory"
        " "
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$character"
      ];     
      add_newline = false;
      
      username = {
        format = "[$user]($style)";
        style_user = "bold #a6e3a1";
        show_always = true;
      };
      
      hostname = {
        format = "[$hostname]($style)";
        style = "bold #f38ba8";
        ssh_only = false;
      };
      
      directory = {
        format = "[$path]($style)";
      };
      
      git_branch = {
        format = " [$symbol$branch]($style)";
        symbol = "";
      };
      
      git_status = {
        format = "[$all_status$ahead_behind]($style)";
      };
      
      nix_shell = {
        format = " [$symbol]($style)";
        symbol = "❄️ ";
      };
      
      character = {
        success_symbol = "[➜](bold #00cc00) ";
        error_symbol = "[✗](bold #ff0000) ";
      };
    };
  };
}
