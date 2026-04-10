-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    window = {
      mappings = {
        ['P'] = { 'toggle_preview', config = { use_float = true, use_image_nvim = true } },
      },
    },
    filesystem = {
      use_libuv_file_watcher = true,
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['<C-h>'] = function() vim.cmd 'TmuxNavigateLeft' end,
          ['<C-j>'] = function() vim.cmd 'TmuxNavigateDown' end,
          ['<C-k>'] = function() vim.cmd 'TmuxNavigateUp' end,
          ['<C-l>'] = function() vim.cmd 'TmuxNavigateRight' end,
        },
      },
    },
  },
}
