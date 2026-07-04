{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;

    extraPackages = with pkgs; [
      lua-language-server
      nixd
      pyright
      typescript-language-server
      gopls

      stylua
      nixfmt-rfc-style
      black
      prettierd
      gofumpt
      gotools
    ];

    plugins = with pkgs.vimPlugins; [
      nvim-cmp
      cmp-nvim-lsp
      cmp-path

      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim

      gitsigns-nvim
      mini-nvim
      conform-nvim
      nvim-autopairs

      (nvim-treesitter.withPlugins (p: [
        p.nix
        p.go
        p.javascript
        p.typescript
        p.tsx
        p.python
        p.lua
        p.json
        p.yaml
        p.toml
        p.markdown
        p.markdown_inline
        p.bash
      ]))
    ];

    initLua = builtins.readFile ./neovim-config.lua;
  };
}
