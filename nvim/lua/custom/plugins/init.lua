-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup {
        -- Oil will use a floating window instead of opening in current window
        default_file_explorer = true,
        columns = {
          'icon',
          -- 'permissions',
          -- 'size',
          -- 'mtime',
        },
        view_options = {
          -- Show files and directories that start with "."
          show_hidden = false,
        },
        keymaps = {
          ['g?'] = 'actions.show_help',
          ['<CR>'] = 'actions.select',
          ['<C-v>'] = 'actions.select_vsplit',
          ['<C-x>'] = 'actions.select_split',
          ['<C-t>'] = 'actions.select_tab',
          ['<C-p>'] = 'actions.preview',
          ['<C-c>'] = 'actions.close',
          ['<C-l>'] = 'actions.refresh',
          ['-'] = 'actions.parent',
          ['_'] = 'actions.open_cwd',
          ['`'] = 'actions.cd',
          ['~'] = 'actions.tcd',
          ['gs'] = 'actions.change_sort',
          ['gx'] = 'actions.open_external',
          ['g.'] = 'actions.toggle_hidden',
        },
      }

      -- Keybinding to open oil in current directory
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory in Oil' })
    end,
  },
}
