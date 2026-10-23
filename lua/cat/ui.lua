-- Colours, icons and the statusline.

if vim.g.fancy then
  require('catppuccin').setup({
    flavour = 'mocha', -- the darkest of the four; try 'macchiato' or 'frappe' for softer
    term_colors = true,
    integrations = {
      blink_cmp = true,
      snacks = { enabled = true },
      mini = { enabled = true },
      neotest = true,
      native_lsp = { enabled = true },
    },
  })
  vim.cmd.colorscheme('catppuccin')
else
  vim.g.rehash256 = 1 -- molokai's 256-colour version that tracks the GUI one closely
  vim.cmd.colorscheme('molokai')
end

-- Icons: real glyphs in a Nerd Font terminal, plain letters otherwise.
require('mini.icons').setup({ style = vim.g.fancy and 'glyph' or 'ascii' })
MiniIcons.mock_nvim_web_devicons() -- for plugins that expect nvim-web-devicons

-- Statusline: mode, git branch and changes, diagnostics, file, LSP, position.
require('mini.statusline').setup({ use_icons = vim.g.fancy })

-- Minimap (neominimap): the file in miniature down the right, with problems, git changes
-- and search matches marked. It gets its own column so it never covers text, and hides
-- when it would leave the code narrower than 100 columns. ,M turns it off/on.
local MINIMAP_WIDTH = 20
local MIN_CODE_WIDTH = 100
local function minimap_win(tabid)
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tabid)) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == 'neominimap' then return w end
  end
end
local last_choice = false
local no_minimap = { 'help', 'bigfile', 'oil', 'snacks_dashboard', 'gitcommit' }
vim.g.neominimap = {
  auto_enable = true,
  layout = 'split',
  split = { minimap_width = MINIMAP_WIDTH, fix_width = true, direction = 'botright', close_if_last_window = true },
  exclude_filetypes = no_minimap,
  diagnostic = { enabled = true },
  git = { enabled = false }, -- that's for gitsigns; mini.diff below instead
  mini_diff = { enabled = true },
  search = { enabled = true },
  treesitter = { enabled = true },
  tab_filter = function(tabid)
    local win = vim.api.nvim_tabpage_get_win(tabid)
    local buf = vim.api.nvim_win_get_buf(win)
    -- Pickers, pop-ups and the minimap itself don't change the decision.
    if vim.api.nvim_win_get_config(win).relative ~= '' or vim.bo[buf].filetype == 'neominimap' then
      return last_choice
    end
    -- How wide this window would be without the minimap next to it.
    local width = vim.api.nvim_win_get_width(win)
    local mw = minimap_win(tabid)
    if mw and vim.api.nvim_win_get_position(win)[2] + width + 1 == vim.api.nvim_win_get_position(mw)[2] then
      width = width + MINIMAP_WIDTH + 1
    end
    last_choice = vim.bo[buf].buftype == ''
      and not vim.tbl_contains(no_minimap, vim.bo[buf].filetype)
      and width - MINIMAP_WIDTH - 1 >= MIN_CODE_WIDTH
    return last_choice
  end,
}
vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized', 'WinEnter', 'BufWinEnter' }, {
  callback = vim.schedule_wrap(function()
    local ok, api = pcall(require, 'neominimap.api')
    if ok then pcall(api.tab.refresh, { vim.api.nvim_get_current_tabpage() }) end
  end),
})
vim.keymap.set('n', '<leader>M', '<Cmd>Neominimap Toggle<CR>', { desc = 'Toggle minimap' })

-- Terminal tab title: the folder Neovim is in, plus Claude's summary of its session when
-- Claude is open (e.g. "~/projects/cat - Add tab titles"). Claude sets its terminal's
-- title as it goes, so the tab follows it (minus the ✳ or spinner it puts in front).
vim.o.title = true
local function is_claude(buf)
  return vim.bo[buf].buftype == 'terminal' and vim.api.nvim_buf_get_name(buf):match('//%d+:.*claude') ~= nil
end
local function claude_title()
  local best
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local t = vim.b[buf].term_title
    if is_claude(buf) and t and not t:match('Claude Code$') then
      if vim.fn.win_findbuf(buf)[1] then return t end -- prefer one that's showing
      best = best or t
    end
  end
  return best
end
local function set_title()
  local title = vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
  local claude = claude_title()
  if claude then
    claude = vim.trim(claude)
    claude = vim.trim(claude:match('^[^%w%s]+%s+(.*)$') or claude) -- drop the "✳ " or spinner
    if claude ~= '' then title = title .. ' - ' .. claude end
  end
  vim.o.titlestring = title:gsub('%%', '%%%%')
end
vim.api.nvim_create_autocmd({ 'VimEnter', 'DirChanged', 'TermRequest', 'TermClose', 'BufWipeout', 'TabEnter' }, {
  callback = vim.schedule_wrap(set_title),
})
set_title()

-- A bell when Claude needs you: when it finishes (the spinner at the start of its title
-- turns back into ✳) or sends a notification (waiting for input, asking permission).
-- Ghostty then puts 🔔 in the tab's title until you go back to it. Only while Neovim
-- isn't focused, so it doesn't ring while you're watching.
local focused = true
vim.api.nvim_create_autocmd('FocusGained', { callback = function() focused = true end })
vim.api.nvim_create_autocmd('FocusLost', { callback = function() focused = false end })
local working = {} -- Claude terminal buffer -> its spinner was going
vim.api.nvim_create_autocmd('TermRequest', {
  callback = function(ev)
    if not is_claude(ev.buf) then return end
    local seq, ring = ev.data.sequence, false
    local title = seq:match('^\27%][02];(.*)')
    if title then
      local busy = title:match('^[^%w%s]') ~= nil and not title:match('^✳')
      ring = working[ev.buf] and not busy
      working[ev.buf] = busy
    else
      -- OSC 777 / OSC 9 notifications, but not OSC 9;4 (progress)
      ring = seq:match('^\27%]777;notify;') or (seq:match('^\27%]9;') and not seq:match('^\27%]9;4;'))
    end
    if ring and not focused then vim.api.nvim_ui_send('\7') end
  end,
})
