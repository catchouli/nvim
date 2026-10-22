local o = vim.opt

o.number = true
o.relativenumber = true
o.signcolumn = 'yes:2' -- room for a diagnostic and a git bar; fixed so text doesn't jump
o.cursorline = true
o.wrap = true
o.linebreak = true
o.breakindent = true
o.scrolloff = 6
o.sidescrolloff = 8

o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true

o.ignorecase = true
o.smartcase = true
o.inccommand = 'split' -- live preview of :s substitutions

o.splitright = true
o.splitbelow = true
o.undofile = true -- undo history survives closing the file
o.updatetime = 250
o.timeoutlen = 400
o.confirm = true -- ask to save instead of refusing to quit
o.mouse = 'a'
o.showmode = false -- the statusline shows the mode
o.laststatus = 3 -- one statusline across the bottom
o.list = true
o.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
o.fillchars = { eob = ' ' }
o.wildignore:append({ '*/target/*', '*/dist/*', '*/node_modules/*', '*/.venv/*' })
o.completeopt = { 'menu', 'menuone', 'noselect', 'popup' }

-- Folds come from treesitter where available; start with everything open.
o.foldlevelstart = 99

vim.diagnostic.config({
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many', anchor_bias = 'above' },
  virtual_text = false, -- shown in a float instead, see below
  signs = vim.g.fancy and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or true,
})

-- When the cursor rests on a problem, show it in a float above the line.
-- Skipped if another float (hover, completion docs) is already open.
vim.api.nvim_create_autocmd('CursorHold', {
  callback = function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative ~= '' then return end
    end
    vim.diagnostic.open_float({ scope = 'cursor', focus = false })
  end,
})

-- Briefly highlight what was just yanked.
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.hl.on_yank() end,
})
