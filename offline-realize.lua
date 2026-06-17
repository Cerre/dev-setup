-- Staging helper (online only): force the async artifacts that a normal
-- headless `+Lazy! restore` does NOT produce — Treesitter grammars and Mason
-- tools — and block until they are actually on disk. Exits non-zero if any are
-- missing, so the bundle build fails loudly instead of shipping incomplete.
--
-- Run as: nvim --headless -c 'luafile offline-realize.lua'   (it quits itself)

local function log(m) io.stderr:write('[realize] ' .. m .. '\n') end

local fail = {}

-- 1. Treesitter grammars (new main-branch API: require('nvim-treesitter').install) ---
local langs = {
  'bash', 'c', 'diff', 'html', 'lua', 'luadoc',
  'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc',
}
log('installing treesitter grammars: ' .. table.concat(langs, ', '))
local ts = require('nvim-treesitter')
pcall(function() ts.install(langs) end)
-- Gate on get_installed() rather than the return value, so we wait for the
-- compiled parsers to actually land regardless of the async handle's shape.
vim.wait(600000, function()
  local have = {}
  for _, l in ipairs(ts.get_installed()) do have[l] = true end
  for _, l in ipairs(langs) do
    if not have[l] then return false end
  end
  return true
end, 1000)
do
  local have = {}
  for _, l in ipairs(ts.get_installed()) do have[l] = true end
  for _, l in ipairs(langs) do
    if not have[l] then fail[#fail + 1] = 'treesitter:' .. l end
  end
end

-- 2. Mason tools (canonical registry names; verified against the configs below) ---
--   basedpyright            <- servers.basedpyright   (init.lua)
--   lua-language-server     <- servers.lua_ls
--   dockerfile-language-server <- servers.dockerls
--   stylua                  <- mason-tool-installer ensure_installed
--   debugpy                 <- mason-nvim-dap ensure_installed (debug.lua)
local mason_targets = {
  'basedpyright', 'lua-language-server', 'dockerfile-language-server',
  'stylua', 'debugpy',
}
local reg = require('mason-registry')
local refreshed = false
reg.refresh(function() refreshed = true end)
vim.wait(60000, function() return refreshed end, 100)

-- IMPORTANT: pkg:is_installed() flips true EARLY (before the download/extract
-- finishes), so polling it races and ships half-installed packages. Wait on the
-- real install:success / install:failed events instead.
local settled = {}  -- name -> true once the install has actually finished
for _, name in ipairs(mason_targets) do
  local ok, pkg = pcall(reg.get_package, name)
  if not ok then
    settled[name] = true
    fail[#fail + 1] = 'mason:' .. name .. '(no-package)'
  elseif pkg:is_installed() and not pkg:is_installing() then
    settled[name] = true
  else
    pkg:once('install:success', function() settled[name] = true end)
    pkg:once('install:failed', function()
      settled[name] = true
      fail[#fail + 1] = 'mason:' .. name .. '(install:failed)'
    end)
    if not pkg:is_installing() then
      log('installing mason: ' .. name)
      pkg:install()
    end
    -- Guard against the install settling between the check and the listener.
    if pkg:is_installed() and not pkg:is_installing() then settled[name] = true end
  end
end
vim.wait(1800000, function()
  for _, name in ipairs(mason_targets) do
    if not settled[name] then return false end
  end
  return true
end, 1000)
-- Final ground-truth check: installed and no longer installing.
for _, name in ipairs(mason_targets) do
  local ok, pkg = pcall(reg.get_package, name)
  if ok and (not pkg:is_installed() or pkg:is_installing()) then
    fail[#fail + 1] = 'mason:' .. name .. '(incomplete)'
  end
end

-- 3. Report + exit code ----------------------------------------------------------
if #fail > 0 then
  log('FAILED to realize: ' .. table.concat(fail, ', '))
  vim.cmd('cquit 1')
else
  log('all treesitter grammars and mason tools realized')
  vim.cmd('qall')
end
