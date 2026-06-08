-- Autocomplete inside the nvim-dap REPL (and dap-ui Watches/Hover).
--
-- blink.cmp (v1.10+) already runs in `dap-repl` / `dapui_*` buffers (it has a
-- built-in exception for them). It just needs a completion SOURCE there.
-- nvim-dap exposes frame-aware completions through the debug adapter; `cmp-dap`
-- surfaces them, and `blink.compat` bridges that source into blink.
return {
  {
    'saghen/blink.cmp',
    dependencies = {
      { 'saghen/blink.compat', version = '*', opts = {} },
      'rcarriga/cmp-dap',
    },
    opts = {
      sources = {
        -- Use ONLY the dap source in these buffers (LSP etc. don't apply there)
        per_filetype = {
          ['dap-repl'] = { 'dap' },
          dapui_watches = { 'dap' },
          dapui_hover = { 'dap' },
        },
        providers = {
          dap = { name = 'dap', module = 'blink.compat.source' },
        },
      },
    },
  },
}
