{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = { };
    # One-shot Claude queries without quoting: `q why is my disk full`.
    # "$*" joins all arguments into a single prompt string.
    initExtra = ''
      q()  { claude -p --model haiku "$*"; }
      qq() { claude -p -c --model haiku "$*"; }
    '';
  };

  programs.fish = {
    enable = true;
    # One-shot Claude queries without quoting: `q why is my disk full`.
    # "$argv" joins all arguments into a single prompt string.
    functions.q = ''claude -p "$argv"'';
    functions.qq = ''claude -p -c "$argv"'';
    # Defining a fish_greeting function supersedes the default greeting,
    # so the old `set fish_greeting` in shellInit is no longer needed.
    functions.fish_greeting = ''
      set -l tips \
        'Press Alt+E to open the current command line in $EDITOR — edit it as multi-line text, save, and it runs.' \
        'The grey text ahead of the cursor is an autosuggestion from your history: Ctrl+Y accepts it all, Alt+F one word.' \
        'dirh shows your directory history; prevd and nextd walk it, and cdh gives you an interactive picker.' \
        'fish generates completions by parsing man pages — run fish_update_completions, then Tab-complete flags for nearly anything.' \
        'Alt+S prepends sudo to the current command line (or to the previous command if the line is empty).' \
        'Command substitution needs no dollar sign: echo (date). Quote it as "(date)" to keep the result one argument.' \
        'Press Alt+L to run ls on the directory token under your cursor without touching the command line.' \
      set_color --bold brcyan
      echo -n '><> fish tip: '
      set_color normal
      echo (random choice $tips)

      bind \cy accept-autosuggestion
    '';
  };
}
