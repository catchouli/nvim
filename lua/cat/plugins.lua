-- Plugins, installed by Neovim's built-in manager (vim.pack, :h vim.pack).
-- Update: :lua vim.pack.update()  (review the changes, then :write to apply).
-- Versions are pinned in nvim-pack-lock.json next to init.lua.

-- Build steps after install/update. Must be registered before vim.pack.add().
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    end
  end,
})

local gh = function(repo) return 'https://github.com/' .. repo end

vim.pack.add({
  -- Look
  gh('catppuccin/nvim'), -- colour scheme (full colour terminals)
  gh('tomasr/molokai'), -- colour scheme for Terminal.app (256 colours)

  -- One plugin, many small modules: statusline, icons, text objects, surround,
  -- easymotion-style jumps, key hints, git signs...
  gh('nvim-mini/mini.nvim'),

  -- Fuzzy finder (CtrlP), start screen, notifications, GitHub PRs/issues...
  gh('folke/snacks.nvim'),

  -- Folders as editable buffers: `nvim .`, or - from any file
  gh('stevearc/oil.nvim'),

  -- Minimap of the file down the right-hand side
  { src = gh('Isrothy/neominimap.nvim'), version = vim.version.range('3.*') },

  -- Syntax trees: better highlighting, folds, text objects
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },

  -- Language servers and completion
  gh('neovim/nvim-lspconfig'), -- ready-made settings for each language server
  { src = gh('saghen/blink.cmp'), version = vim.version.range('1.*') }, -- completion menu
  { src = gh('mrcjkb/rustaceanvim'), version = vim.version.range('9.*') }, -- Rust: runnables, macro expansion, debugging
  gh('saecki/crates.nvim'), -- Cargo.toml: versions and features inline

  -- Tests (set up on first use, see tools.lua)
  gh('nvim-lua/plenary.nvim'),
  gh('nvim-neotest/nvim-nio'),
  gh('nvim-neotest/neotest'),
  gh('nvim-neotest/neotest-python'),

  -- Reviewing changes: every changed file in a tree, each one side by side
  gh('sindrets/diffview.nvim'),

  -- Claude Code in a split, with your selection and diffs shared both ways
  gh('coder/claudecode.nvim'),
}, { confirm = false })
