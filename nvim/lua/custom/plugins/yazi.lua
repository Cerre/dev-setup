-- Yazi file manager integration (browse files with preview, including images)
return {
  'mikavilpas/yazi.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { '<leader>-', '<cmd>Yazi<cr>', desc = 'Open Yazi at current file' },
    { '<leader>cw', '<cmd>Yazi cwd<cr>', desc = 'Open Yazi in working directory' },
  },
  opts = {
    open_for_directories = true,
  },
}
