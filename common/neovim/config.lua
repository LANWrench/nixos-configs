-- ============================================================================
-- Options
-- ============================================================================

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = 'a'

vim.opt.clipboard = 'unnamedplus'

vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = 'yes'

vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.cursorline = true
vim.opt.scrolloff = 10

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·' }

-- ============================================================================
-- Keymaps
-- ============================================================================

-- Clear search highlight
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Ctrl+hjkl moves between splits and tmux panes: mapped by vim-tmux-navigator.

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>')

-- ============================================================================
-- Filetypes
-- ============================================================================

-- Neovim maps .tf to TinyFugue ('tf') by default; we only ever mean Terraform.
vim.filetype.add { extension = { tf = 'terraform' } }

-- ============================================================================
-- Treesitter
-- ============================================================================

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- ============================================================================
-- LSP
-- ============================================================================

vim.diagnostic.config {
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = { spacing = 4 },
}

vim.lsp.config['lua_ls'] = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.git' },
  settings = {
    Lua = {
      diagnostics = { globals = { 'vim' } },
      completion = { callSnippet = 'Replace' },
    },
  },
}

vim.lsp.config['nixd'] = {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
}

vim.lsp.config['pyright'] = {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' },
}

vim.lsp.config['ts_ls'] = {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'package.json', 'tsconfig.json', '.git' },
}

vim.lsp.config['gopls'] = {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork' },
  root_markers = { 'go.mod', 'go.work', '.git' },
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
    },
  },
}

vim.lsp.config['svelte'] = {
  cmd = { 'svelteserver', '--stdio' },
  filetypes = { 'svelte' },
  root_markers = { 'package.json', '.git' },
}

-- Only attaches in projects that have an ESLint config (workspace_required),
-- and uses the project's own eslint from node_modules — run `npm install` first.
vim.lsp.config['eslint'] = {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'svelte' },
  root_markers = {
    'eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs', 'eslint.config.ts',
    '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yml', '.eslintrc.yaml',
  },
  workspace_required = true,
  settings = {
    validate = 'on',
    run = 'onType',
    format = false, -- prettier formats; eslint only lints
    nodePath = '',
    workingDirectory = { mode = 'auto' },
    experimental = {},
    problems = { shortenToSingleLine = false },
    codeAction = {
      disableRuleComment = { enable = true, location = 'separateLine' },
      showDocumentation = { enable = true },
    },
  },
  -- The server is written for VS Code and won't lint without a workspaceFolder.
  before_init = function(_, config)
    config.settings.workspaceFolder = {
      uri = vim.uri_from_fname(config.root_dir),
      name = vim.fn.fnamemodify(config.root_dir, ':t'),
    }
  end,
  handlers = {
    -- Asks "may I run this project's eslint?" — 4 = approved.
    ['eslint/confirmESLintExecution'] = function() return 4 end,
    ['eslint/openDoc'] = function(_, result)
      vim.ui.open(result.url)
      return {}
    end,
    ['eslint/noLibrary'] = function()
      vim.notify('ESLint: no eslint in node_modules (run npm install)', vim.log.levels.WARN)
      return {}
    end,
    ['eslint/probeFailed'] = function()
      vim.notify('ESLint: probe failed', vim.log.levels.WARN)
      return {}
    end,
  },
}

vim.lsp.config['terraformls'] = {
  cmd = { 'terraform-ls', 'serve' },
  filetypes = { 'terraform', 'terraform-vars' },
  root_markers = { '.terraform', '.git' },
}

vim.lsp.enable { 'lua_ls', 'nixd', 'pyright', 'ts_ls', 'gopls', 'svelte', 'eslint', 'terraformls' }

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = desc })
    end

    map('gd', require('telescope.builtin').lsp_definitions,  'Go to definition')
    map('gr', require('telescope.builtin').lsp_references,   'Go to references')
    map('K', vim.lsp.buf.hover, 'Hover documentation')
    map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
    map('[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
    map(']d', vim.diagnostic.goto_next, 'Next diagnostic')
  end,
})

-- ============================================================================
-- Telescope
-- ============================================================================

require('telescope').setup {
  defaults = {
    file_ignore_patterns = { 'node_modules', '.git/' },
  },
}

pcall(require('telescope').load_extension, 'fzf')

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Search files' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep,  { desc = 'Search by grep' })
vim.keymap.set('n', '<leader>sb', builtin.buffers,    { desc = 'Search buffers' })
vim.keymap.set('n', '<leader>sh', builtin.help_tags,  { desc = 'Search help' })
vim.keymap.set('n', '<leader>sr', builtin.resume,     { desc = 'Resume last search' })

-- ============================================================================
-- Autocompletion
-- ============================================================================

-- Advertise enhanced capabilities to LSP servers so they send richer completion data
vim.lsp.config('*', {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

local cmp = require('cmp')

cmp.setup {
  completion = { completeopt = 'menu,menuone,noinsert' },

  sources = {
    { name = 'nvim_lsp' },
    { name = 'path' },
  },

  mapping = cmp.mapping.preset.insert {
    ['<C-n>']     = cmp.mapping.select_next_item(),
    ['<C-p>']     = cmp.mapping.select_prev_item(),
    ['<C-y>']     = cmp.mapping.confirm { select = true },
    ['<C-e>']     = cmp.mapping.abort(),
    ['<C-Space>'] = cmp.mapping.complete(),
  },
}

-- ============================================================================
-- Gitsigns
-- ============================================================================

require('gitsigns').setup {
  signs = {
    add          = { text = '+' },
    change       = { text = '~' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    local gs = require('gitsigns')
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    map(']h', gs.next_hunk,                    'Next hunk')
    map('[h', gs.prev_hunk,                    'Previous hunk')
    map('<leader>hs', gs.stage_hunk,           'Stage hunk')
    map('<leader>hr', gs.reset_hunk,           'Reset hunk')
    map('<leader>hp', gs.preview_hunk,         'Preview hunk')
    map('<leader>hb', gs.toggle_current_line_blame, 'Toggle line blame')
  end,
}

-- ============================================================================
-- Mini
-- ============================================================================

require('mini.files').setup()

vim.keymap.set('n', '<leader>e', function()
  require('mini.files').open(vim.api.nvim_buf_get_name(0))
end, { desc = 'Open file explorer' })

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
      require('mini.files').open(vim.fn.argv(0))
    end
  end,
})

-- ============================================================================
-- Conform (format on save)
-- ============================================================================

require('conform').setup {
  formatters_by_ft = {
    lua        = { 'stylua' },
    nix        = { 'nixfmt' },
    python     = { 'black' },
    javascript = { 'prettierd' },
    typescript = { 'prettierd' },
    javascriptreact = { 'prettierd' },
    typescriptreact = { 'prettierd' },
    svelte     = { 'prettierd' }, -- needs the project's prettier-plugin-svelte
    go         = { 'gofumpt', 'goimports' },
    terraform  = { 'tofu_fmt' },
    ['terraform-vars'] = { 'tofu_fmt' },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

-- ============================================================================
-- Autopairs
-- ============================================================================

require('nvim-autopairs').setup()

-- ============================================================================
-- Autocommands
-- ============================================================================

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})
