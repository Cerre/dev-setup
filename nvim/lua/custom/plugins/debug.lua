-- Python debugger configuration
-- Uses nvim-dap (Debug Adapter Protocol) - same protocol as VS Code

-- Toggle stopping on exceptions, so they break at the throw site.
--   'uncaught'      -> exceptions that escape everything and crash the process
--   'userUnhandled' -> exceptions that escape YOUR code even if a framework
--                      catches them later (e.g. pytest catching an assert -> a
--                      failing test still stops at the assert line)
local exception_bp_on = false
local function toggle_exception_breakpoints()
  exception_bp_on = not exception_bp_on
  require('dap').set_exception_breakpoints(exception_bp_on and { 'uncaught', 'userUnhandled' } or {})
  vim.notify('Exception breakpoints: ' .. (exception_bp_on and 'ON (uncaught + userUnhandled)' or 'OFF'), vim.log.levels.INFO)
end

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI (like VS Code)
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Python debugger
    'mfussenegger/nvim-dap-python',
  },
  keys = {
    -- Debugging keymaps (using leader-based keys for better terminal compatibility)
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Continue',
    },
    {
      '<leader>dn',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over (Next)',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<leader>do',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    -- Run the program until it reaches the line under the cursor (no breakpoint needed)
    {
      '<leader>dC',
      function()
        require('dap').run_to_cursor()
      end,
      desc = 'Debug: Run to Cursor',
    },
    -- Debug the pytest test under the cursor (uses dap-python)
    {
      '<leader>dm',
      function()
        require('dap-python').test_method()
      end,
      desc = 'Debug: Test Method under cursor',
    },
    {
      '<leader>dM',
      function()
        require('dap-python').test_class()
      end,
      desc = 'Debug: Test Class under cursor',
    },
    -- Toggle stopping on uncaught exceptions (catch crashes at the throw site)
    {
      '<leader>dE',
      toggle_exception_breakpoints,
      desc = 'Debug: Toggle Exception breakpoints',
    },
    -- Logpoint: print a message when this line is hit, without stopping
    {
      '<leader>dL',
      function()
        require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ')
      end,
      desc = 'Debug: Set Logpoint',
    },
    -- VS Code-style function-key bindings (F5 Continue is defined above)
    {
      '<F9>',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<F10>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F11>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F12>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Conditional Breakpoint',
    },
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: Toggle UI',
    },
    {
      '<leader>dt',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: Toggle UI',
    },
    {
      '<leader>de',
      function()
        require('dapui').eval()
      end,
      mode = { 'n', 'v' },
      desc = 'Debug: Evaluate expression (cursor word / visual selection)',
    },
    {
      '<leader>dw',
      function()
        require('dapui').elements.watches.add(vim.fn.expand '<cexpr>')
      end,
      desc = 'Debug: Add expression under cursor to Watches',
    },
    {
      '<leader>dr',
      function()
        require('dap').repl.toggle()
      end,
      desc = 'Debug: Toggle REPL/Console',
    },
    {
      '<leader>dl',
      function()
        require('dap').run_last()
      end,
      desc = 'Debug: Run Last',
    },
    {
      '<leader>dx',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: Terminate',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Mason setup for automatic debugger installation
    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'debugpy', -- Python debugger
      },
    }

    -- DAP UI setup (VS Code-like interface)
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 0.25 },
            { id = 'breakpoints', size = 0.25 },
            { id = 'stacks', size = 0.25 },
            { id = 'watches', size = 0.25 },
          },
          size = 80,
          position = 'left',
        },
        {
          elements = {
            { id = 'repl', size = 0.5 },
            { id = 'console', size = 0.5 },
          },
          size = 0.375,
          position = 'bottom',
        },
      },
    }

    -- Auto-OPEN the DAP UI when a session starts.
    -- We deliberately do NOT auto-close on exit/terminate, so the console panel
    -- (program stdout + the final "X passed, Y failed" pytest summary) stays
    -- visible after the run finishes. Close it manually with <leader>dt.
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open

    -- Python debugger setup
    -- Automatically detect .venv or fall back to system python
    local function get_python_path()
      local venv_path = vim.fn.getcwd() .. '/.venv'
      local home_venv_path = vim.fn.expand '~/.venv'

      if vim.fn.isdirectory(venv_path) == 1 then
        return venv_path .. '/bin/python'
      elseif vim.fn.isdirectory(home_venv_path) == 1 then
        return home_venv_path .. '/bin/python'
      else
        return 'python3'
      end
    end

    require('dap-python').setup(get_python_path())

    -- Alias so .vscode/launch.json configs with "type": "debugpy" work
    dap.adapters.debugpy = dap.adapters.python

    -- Load .vscode/launch.json configurations
    require('dap.ext.vscode').load_launchjs()
  end,
}
