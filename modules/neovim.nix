{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    # Install language servers, formatters, and other tools
    extraPackages = with pkgs; [
      # LSP Servers
      lua-language-server
      nixd                          # Nix LSP
      nil                           # Alternative Nix LSP
      pyright                       # Python
      typescript-language-server    # TypeScript/JavaScript
      rust-analyzer                 # Rust
      gopls                         # Go LSP
      omnisharp-roslyn              # C# LSP

      # Formatters
      stylua                        # Lua formatter
      nixpkgs-fmt                   # Nix formatter
      black                         # Python formatter
      gofumpt                       # Go formatter (stricter than gofmt)
      gotools                       # Includes goimports
      csharpier                     # C# formatter
      prettierd                     # JavaScript/TypeScript formatter (faster prettier)

      # Linters
      golangci-lint                 # Go linter
      eslint_d                      # JavaScript/TypeScript linter (faster)

      # Other tools
      ripgrep                       # Required for Telescope live_grep
      fd                            # Better find, used by Telescope
      tree-sitter                   # Treesitter CLI

      # Go-specific tools
      delve                         # Go debugger
      go-tools                      # Additional Go tools (staticcheck, etc.)
    ];

    # Plugins managed by Nix (instead of lazy.nvim)
    plugins = with pkgs.vimPlugins; [
      # Core plugins for kickstart functionality
      plenary-nvim                  # Required dependency for many plugins

      # Fuzzy finder
      telescope-nvim
      telescope-fzf-native-nvim     # Native FZF sorter for better performance
      telescope-ui-select-nvim      # Use telescope for vim.ui.select

      # LSP UI improvements (fidget is still useful for progress indicators)
      fidget-nvim                   # LSP status updates

      # Autocompletion
      nvim-cmp
      cmp-nvim-lsp
      cmp-path
      cmp-buffer

      # Snippet engine
      luasnip
      cmp_luasnip
      friendly-snippets

      # Syntax highlighting and parsing
      (nvim-treesitter.withPlugins (p: [
        p.bash
        p.c
        p.diff
        p.html
        p.lua
        p.luadoc
        p.markdown
        p.markdown_inline
        p.python
        p.query
        p.vim
        p.vimdoc
        p.rust
	p.svelte
        p.javascript
        p.typescript
        p.tsx                       # TypeScript React
        p.nix
        p.go                        # Go grammar
        p.c_sharp                   # C# grammar
        p.json                      # JSON
        p.yaml                      # YAML
        p.toml                      # TOML
        p.css                       # CSS
        p.html                      # HTML
      ]))
      nvim-treesitter-textobjects

      # Useful plugins
      which-key-nvim                # Show keybindings
      gitsigns-nvim                 # Git integration
      indent-blankline-nvim         # Indentation guides
      comment-nvim                  # Easy commenting
      todo-comments-nvim            # Highlight TODO comments
      mini-nvim                     # Collection of minimal plugins

      # Colorscheme (Stylix may override this)
      catppuccin-nvim
    ];

    # Load Lua config from external file
    extraLuaConfig = builtins.readFile ./neovim-config.lua;
  };
}
