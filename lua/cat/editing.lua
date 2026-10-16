-- Editing helpers, mostly from mini.nvim (one plugin, pick the modules you want).

-- Better text objects: a/i for arguments (a), function calls (f), quotes (q),
-- brackets (b)... e.g. `cia` changes an argument, `daf` deletes a call.
require('mini.ai').setup()

-- Surround: sa{motion}{char} add, sd{char} delete, sr{old}{new} replace.
-- e.g. `saiw)` wraps a word in (), `sd"` removes quotes, `sr)]` swaps () for [].
require('mini.surround').setup()

-- EasyMotion-style jumps, on EasyMotion's old key: <leader><leader>, type the
-- character you're looking at, then the letter that appears on it.
require('mini.jump2d').setup({
  labels = 'aoeuidhtnspyfgcrlqjkxbmwvz', -- Dvorak home row first
  view = { dim = true },
  mappings = { start_jumping = '' },
})
vim.keymap.set({ 'n', 'x', 'o' }, '<leader><leader>', function()
  MiniJump2d.start(MiniJump2d.builtin_opts.single_character)
end, { desc = 'Jump to a character on screen' })

-- Highlights TODO/FIXME/HACK/NOTE and #rrggbb colours in place.
local hi = require('mini.hipatterns')
hi.setup({
  highlighters = {
    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
    hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
    todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
    note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
    hex_color = hi.gen_highlighter.hex_color(),
  },
})

-- Key hints: press <leader>, g, z, [, ], <C-w> or " and wait to see what comes next.
local clue = require('mini.clue')
clue.setup({
  triggers = {
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },
    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },
    { mode = 'n', keys = 'z' },
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
    { mode = 'n', keys = '<C-w>' },
    { mode = 'n', keys = '"' },
    { mode = 'n', keys = "'" },
    { mode = 'n', keys = '`' },
    { mode = 'i', keys = '<C-r>' },
  },
  clues = {
    { mode = 'n', keys = '<Leader>a', desc = '+Claude Code' },
    { mode = 'n', keys = '<Leader>g', desc = '+Git / GitHub' },
    { mode = 'n', keys = '<Leader>t', desc = '+Tests' },
    { mode = 'n', keys = '<Leader>r', desc = '+Rust' },
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
  },
  window = { delay = 300, config = { width = 'auto' } },
})

-- Syntax trees: highlighting and folds. The language list is in languages.lua.
local langs = require('cat.languages')
if vim.fn.executable('tree-sitter') == 1 then
  require('nvim-treesitter').install(langs)
end
vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev)
    if not pcall(vim.treesitter.start, ev.buf) then return end -- no parser for this filetype
    vim.wo[0][0].foldmethod = 'expr'
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end,
})
