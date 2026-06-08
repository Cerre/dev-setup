-- VS Code-like IDE layer for kickstart.nvim
-- Everything here is additive. To revert to the previous look/feel, delete this
-- file (and re-enable monokai in init.lua). The pre-modernization config is also
-- preserved on the `nvim-backup-2026-06-07` git branch.

return {
  -- ===========================================================================
  -- Theme: literal VS Code Dark+ colors
  -- ===========================================================================
  {
    'Mofiqul/vscode.nvim',
    priority = 1000, -- load before everything else
    config = function()
      require('vscode').setup {
        style = 'dark',
        transparent = false,
        italic_comments = true,
        underline_links = true,
        -- Let the theme own background dimming where possible
        disable_nvimtree_bg = true,
      }
      vim.cmd.colorscheme 'vscode'

      -- Dim inactive splits (kept from the previous config)
      vim.api.nvim_set_hl(0, 'NormalNC', { bg = '#1e1e1e' })
      -- Fade unused variables like VS Code (LSP "Unnecessary" tag)
      vim.api.nvim_set_hl(0, 'DiagnosticUnnecessary', { fg = '#6a737d' })
    end,
  },

  -- ===========================================================================
  -- Statusline (richer than mini.statusline; mini.statusline is disabled in init.lua)
  -- ===========================================================================
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
      options = {
        theme = 'auto',
        globalstatus = true,
        component_separators = { left = '│', right = '│' },
        section_separators = { left = '', right = '' },
      },
      sections = {
        lualine_c = { { 'filename', path = 1 } }, -- relative path, like VS Code
        lualine_x = { 'diagnostics', 'filetype' },
      },
    },
  },

  -- ===========================================================================
  -- Buffer tabs across the top (VS Code editor tabs)
  -- ===========================================================================
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    keys = {
      { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer tab' },
      { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer tab' },
      { '<leader>bp', '<cmd>BufferLineTogglePin<cr>', desc = '[B]uffer [P]in' },
      { '<leader>bd', '<cmd>bdelete<cr>', desc = '[B]uffer [D]elete' },
    },
    opts = {
      options = {
        diagnostics = 'nvim_lsp', -- show LSP error/warn counts on tabs, like VS Code
        offsets = {
          { filetype = 'aerial', text = 'Outline', highlight = 'Directory', separator = true },
          { filetype = 'neo-tree', text = 'Explorer', highlight = 'Directory', separator = true },
        },
        show_buffer_close_icons = true,
        show_close_icon = false,
      },
    },
  },

  -- ===========================================================================
  -- Breadcrumbs / winbar (VS Code's "path > Class > method" trail)
  -- ===========================================================================
  {
    'utilyre/barbecue.nvim',
    name = 'barbecue',
    version = '*',
    dependencies = {
      'SmiteshP/nvim-navic',
      'nvim-tree/nvim-web-devicons',
    },
    event = 'VeryLazy',
    opts = {
      attach_navic = true, -- attach to LSP automatically for symbol context
      show_dirname = true,
      show_basename = true,
    },
  },

  -- ===========================================================================
  -- Symbol outline panel (VS Code's Outline view)
  -- ===========================================================================
  {
    'stevearc/aerial.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<leader>o', '<cmd>AerialToggle!<cr>', desc = 'Toggle [O]utline (symbols)' },
    },
    opts = {
      layout = { default_direction = 'right', min_width = 30 },
      backends = { 'lsp', 'treesitter', 'markdown' },
      show_guides = true,
    },
  },

  -- ===========================================================================
  -- VS Code-style inline diagnostics (clean, current-line only)
  -- ===========================================================================
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'LspAttach',
    priority = 1000,
    config = function()
      require('tiny-inline-diagnostic').setup {
        preset = 'modern',
        options = {
          show_source = false,
          use_icons_from_diagnostic = true,
          multilines = { enabled = true, always_show = false },
          -- Only the line under the cursor, like VS Code — keeps the buffer quiet
          show_all_diags_on_cursorline = false,
        },
      }
      -- This plugin renders diagnostics itself; turn off Neovim's native virtual text
      vim.diagnostic.config { virtual_text = false }
    end,
  },

  -- ===========================================================================
  -- Inline variable values while debugging (VS Code shows these next to code)
  -- ===========================================================================
  {
    'theHamsta/nvim-dap-virtual-text',
    dependencies = { 'mfussenegger/nvim-dap' },
    opts = {
      commented = true,
    },
  },

  -- ===========================================================================
  -- Quality-of-life: lazygit UI, indent guides, nicer notifications
  -- ===========================================================================
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      indent = { enabled = true }, -- VS Code-style indent guides
      notifier = { enabled = true, timeout = 3000 }, -- toast notifications
      lazygit = { enabled = true }, -- full git UI (requires `lazygit` on PATH)
      -- bigfile intentionally disabled: init.lua already has a large-file autocmd
      bigfile = { enabled = false },
    },
    keys = {
      {
        '<leader>gg',
        function()
          require('snacks').lazygit()
        end,
        desc = 'Lazy[g]it',
      },
      {
        '<leader>gl',
        function()
          require('snacks').lazygit.log()
        end,
        desc = 'Lazygit [L]og',
      },
      {
        '<leader>bD',
        function()
          require('snacks').bufdelete()
        end,
        desc = '[B]uffer [D]elete (keep window)',
      },
    },
  },
}
