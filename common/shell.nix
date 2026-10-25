{ config, pkgs, ... }:

{
  home-manager.users.michael = {
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
      # Tips are everyday Vim moves plus the mappings from common/neovim/config.lua
      # (leader = Space) — keep them in sync if a mapping changes there.
      functions.fish_greeting = ''
        set -l tips \
          '. repeats your last change. Change one word with ciw, then jump to the next spot and press . to do it again.' \
          'ci" changes everything inside the quotes (also ci( ci{ ci[). di" deletes it, yi" copies it.' \
          '* searches for the word under the cursor. n / N jump to the next / previous match; Esc clears the highlight.' \
          ':%s/old/new/gc replaces across the file and asks before each one (y = yes, n = skip, a = all).' \
          'u undoes, Ctrl+R redoes. Undo history is saved to disk, so it survives closing and reopening the file.' \
          'Yanks (y) go straight to the system clipboard, and p pastes whatever you copied in other apps.' \
          'The gutter shows relative line numbers: 5j moves down 5 lines, d3k deletes the current line and 3 above.' \
          'f<char> jumps to the next <char> on the line (F goes backward). ; repeats the jump, , reverses it.' \
          '% jumps between matching brackets. d% deletes from here to the matching bracket.' \
          'o / O open a new line below / above. A appends at the end of the line, I inserts at the start.' \
          'V selects whole lines. Then > / < indent, and gv reselects the last selection to do it again.' \
          'Ctrl+V selects a block. Press I, type text, then Esc, and it is inserted on every selected line.' \
          'Record a macro: qa, do the edit, q. Replay it with @a, and @@ replays it again (10@a = ten times).' \
          'Ctrl+O jumps back to where you were (for example after gd), and Ctrl+I jumps forward again.' \
          'Space sf finds files, Space sg greps the whole project, Space sb switches buffers, Space sr reopens the last search.' \
          'gd goes to the definition, gr lists references, and K shows docs for the symbol under the cursor.' \
          'Space rn renames a symbol everywhere (LSP). Space ca shows code actions: quick fixes, imports, refactors.' \
          ']d / [d jump to the next / previous diagnostic (error or warning).' \
          ']h / [h jump between git changes. Space hp previews one, Space hs stages it, Space hr resets it.' \
          'Space hb toggles inline git blame for the current line.' \
          'Space e opens the file explorer. Rename, create or delete files by editing the list like text, then press = to apply.' \
          ':vs and :sp split the window. Ctrl+H/J/K/L moves between splits.' \
          'Space sh searches Vim help. :help <topic> works too, and :Tutor is a 30-minute hands-on refresher.'
        set_color --bold brgreen
        echo -n 'nvim tip: '
        set_color normal
        echo (random choice $tips)
      '';

      # Key bindings — here (not per host) so every machine behaves the same.
      # Ctrl+Y accepts the grey autosuggestion (fish's default is Right/Ctrl+F).
      interactiveShellInit = ''
        bind \cy accept-autosuggestion
      '';
    };
  };
}
