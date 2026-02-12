-- Python debugger configuration
-- Uses nvim-dap (Debug Adapter Protocol) - same protocol as VS Code

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

    -- Automatically open/close DAP UI
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Python debugger setup
    -- Automatically detect .venv or fall back to system python
    local function get_python_path()
      local venv_path = vim.fn.getcwd() .. '/.venv'
      local home_venv_path = vim.fn.expand('~/.venv')

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
