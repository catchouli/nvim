-- Cat's Neovim config (Neovim 0.12+). See README.md for setup and the key cheat sheet.

vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Full colour and icon glyphs need a modern terminal (Ghostty, WezTerm, kitty...).
-- Apple's Terminal.app on macOS 14 has 256 colours and no Nerd Font, so it gets a plain fallback.
vim.g.fancy = vim.env.TERM_PROGRAM ~= 'Apple_Terminal'
if vim.g.fancy then vim.o.termguicolors = true end

require('cat.options')
require('cat.keymaps')
require('cat.plugins') -- installs and loads everything below
require('cat.ui')
require('cat.editing')
require('cat.lsp')
require('cat.tools')
