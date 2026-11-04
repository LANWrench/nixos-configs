{ config, pkgs, ... }:

{
  home-manager.users.michael = {
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
        svelte-language-server
        vscode-langservers-extracted # provides vscode-eslint-language-server
        terraform-ls

        stylua
        nixfmt-rfc-style
        black
        prettierd
        gofumpt
        gotools
        opentofu # `tofu fmt` for .tf files (same canonical style as `terraform fmt`)
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
        vim-tmux-navigator

        (nvim-treesitter.withPlugins (p: [
          p.nix
          p.go
          p.javascript
          p.typescript
          p.tsx
          p.svelte
          p.css
          p.terraform
          p.hcl
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

      initLua = builtins.readFile ./config.lua;
    };
  };
}
