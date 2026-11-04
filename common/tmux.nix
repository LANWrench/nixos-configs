{ pkgs, ... }:

# tmux, the sesh session picker, and zoxide (sesh's source of frequent dirs).
# fzf lives in common/cli.nix. Neovim's half of the Ctrl+h/j/k/l navigation is
# the vim-tmux-navigator plugin in common/neovim/default.nix.
{
  home-manager.users.michael = {
    home.packages = [ pkgs.sesh ];

    programs.zoxide.enable = true;

    programs.tmux = {
      enable = true;
      prefix = "C-Space"; # double-tap to send it through (nvim-cmp's manual completion)
      terminal = "tmux-256color";
      keyMode = "vi";
      mouse = true; # hold Shift to use the terminal's own selection
      baseIndex = 1;
      focusEvents = true;
      historyLimit = 50000;

      # Plugin order matters: home-manager writes this list in order, then
      # extraConfig AFTER it. Continuum's autosave hooks into status-right when
      # it loads, so status-right must be set before that and never in
      # extraConfig, or saving silently stops. Continuum stays last.
      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        {
          plugin = catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavor "mocha"
            set -g @catppuccin_window_status_style "rounded"
            set -g @catppuccin_window_text " #W"
            set -g @catppuccin_window_current_text " #W"
          '';
        }
        {
          plugin = resurrect;
          # Resurrect saves commands as /nix/store/.../bin/nvim, but only restores
          # ones that start with the bare name, so nvim would not come back.
          extraConfig = ''
            set -g @resurrect-hook-post-save-layout "sed -i 's#:/nix/store/[^/]*/bin/#:#'"
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g status-left-length 100
            set -g status-right-length 100
            set -g status-left ""
            set -g status-right "#{E:@catppuccin_status_directory}#{E:@catppuccin_status_session}"

            set -g @continuum-restore "on"
            set -g @continuum-save-interval "10"
          '';
        }
      ];

      extraConfig = ''
        # True color through the outer terminal (Windows Terminal, kitty)
        set -as terminal-features ",xterm-256color:RGB,xterm-kitty:RGB"

        # Copies reach the system clipboard via OSC 52
        set -g set-clipboard on

        set -g renumber-windows on

        # Closing a session switches to another one instead of detaching
        set -g detach-on-destroy off

        # Vim-style selection in copy mode
        bind -T copy-mode-vi v send-keys -X begin-selection
        bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        # New panes and windows open in the current directory
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # prefix + s: fuzzy-pick or create a session
        bind s display-popup -E -w 80% -h 70% "sesh connect \"$(sesh list | fzf --reverse --prompt 'session> ')\""

        # prefix + L: jump back to the last session
        bind L run-shell "sesh last"
      '';
    };
  };
}
