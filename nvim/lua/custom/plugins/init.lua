return {
  -- Telescope zoxide integration
  {
    'jvgrootveld/telescope-zoxide',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension 'zoxide'
      vim.keymap.set('n', '<leader>sz', require('telescope').extensions.zoxide.list, { desc = '[S]earch [Z]oxide' })
    end,
  },

  -- Telescope file browser: visually navigate dirs then search in them
  {
    'nvim-telescope/telescope-file-browser.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    config = function()
      local telescope = require 'telescope'
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'
      local builtin = require 'telescope.builtin'

      telescope.setup {
        extensions = {
          file_browser = {
            hijack_netrw = false,
            mappings = {
              ['i'] = {
                -- Find files in the currently browsed directory
                ['<C-f>'] = function(prompt_bufnr)
                  local dir = action_state.get_current_picker(prompt_bufnr).finder.path
                  actions.close(prompt_bufnr)
                  builtin.find_files { cwd = dir }
                end,
                -- Live grep in the currently browsed directory
                ['<C-g>'] = function(prompt_bufnr)
                  local dir = action_state.get_current_picker(prompt_bufnr).finder.path
                  actions.close(prompt_bufnr)
                  builtin.live_grep { cwd = dir }
                end,
              },
            },
          },
        },
      }

      telescope.load_extension 'file_browser'
    end,
  },
}
