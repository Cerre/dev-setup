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
}
