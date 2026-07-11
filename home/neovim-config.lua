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

-- Move between splits with Ctrl+hjkl
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>')

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

vim.lsp.enable { 'lua_ls', 'nixd', 'pyright', 'ts_ls', 'gopls' }

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
    go         = { 'gofumpt', 'goimports' },
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
