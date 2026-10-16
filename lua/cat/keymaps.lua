-- General keys. Plugin keys live next to their plugin; all of them show up in the
-- popup after pressing <leader> (mini.clue).
local map = vim.keymap.set

-- Enter clears the search highlight (from the old vimrc), but still works in
-- quickfix lists and the like when nothing is highlighted.
map('n', '<CR>', function()
  if vim.v.hlsearch == 1 then return '<Cmd>nohlsearch<CR>' end
  return '<CR>'
end, { expr = true, desc = 'Clear search highlight' })

-- Shift-Insert pastes the system clipboard (old vimrc).
map('i', '<S-Insert>', '<C-r>+')
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to clipboard' })

-- Windows
map('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-l>', '<C-w>l', { desc = 'Window right' })

-- Move selected lines up and down
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move lines down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move lines up' })

-- Diagnostics (Neovim already has [d ]d and <C-w>d)
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show error under cursor' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Errors in location list' })

-- Terminal: Esc gets back to normal mode (old vimrc; except in Claude's split, where Esc
-- goes to Claude); no line numbers in terminals. Ctrl-h / Ctrl-l move to the window on
-- the left / right straight from a terminal, e.g. from Claude back to your file.
map('t', '<Esc>', [[<C-\><C-n>]], { desc = 'Leave terminal mode' })
map('t', '<C-h>', [[<C-\><C-n><C-w>h]], { desc = 'Window left' })
map('t', '<C-l>', [[<C-\><C-n><C-w>l]], { desc = 'Window right' })

-- Coming back to a tab (e.g. closing the review), terminals in it can be left half-drawn:
-- Claude only redraws properly when its size changes. Nudge each terminal window one
-- column narrower and back, which makes it redraw.
vim.api.nvim_create_autocmd('TabEnter', {
  callback = function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      local width = vim.api.nvim_win_get_width(win)
      if vim.bo[buf].buftype == 'terminal' and width > 1 then
        vim.api.nvim_win_set_width(win, width - 1)
        vim.defer_fn(function()
          if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_set_width(win, width) end
        end, 50)
      end
    end
  end,
})
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
    vim.cmd.startinsert()
  end,
})
