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
        'abbr -a gs git status — abbreviations expand in place as you type, so history records the full command (unlike aliases).' \
        'set -U name value creates a universal variable: it persists across reboots and syncs to every open fish instantly, no config file.' \
        'string is a builtin text toolkit — try: string split , "a,b,c"  or  string replace -r "\d+" N "issue 42"' \
        'funced myfn opens a function in your editor for live editing; funcsave myfn then makes it permanent.' \
        'Type a few letters of an old command and press Ctrl+P — fish searches history by that prefix, not just the last command.' \
        'The grey text ahead of the cursor is an autosuggestion from your history: Ctrl+F accepts it all, Alt+F one word.' \
        'dirh shows your directory history; prevd and nextd walk it, and cdh gives you an interactive picker.' \
        'fish generates completions by parsing man pages — run fish_update_completions, then Tab-complete flags for nearly anything.' \
        'math is a builtin: math "2 * pi * 6371" — no bc, no $((...)).' \
        'Alt+S prepends sudo to the current command line (or to the previous command if the line is empty).' \
        'vared PATH edits a variable interactively — PATH is a real list in fish, not a colon-delimited string.' \
        'Command substitution needs no dollar sign: echo (date). Quote it as "(date)" to keep the result one argument.' \
        'random choice a b c picks one argument at random — this very tip system is built on it.' \
        'Press Alt+L to run ls on the directory token under your cursor without touching the command line.' \
        'path is a builtin for path math: ls | path filter -d keeps only directories; path change-extension works on whole lists.'
      set_color --bold brcyan
      echo -n '><> fish tip: '
      set_color normal
      echo (random choice $tips)
    '';
  };
}
