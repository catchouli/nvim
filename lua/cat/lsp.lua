-- Language servers, completion and formatting.
--
-- Neovim's built-in LSP keys (always on when a server is attached):
--   K hover docs · grn rename · gra code action · grr references · gri implementation
--   grt type definition · gO symbols in file · <C-s> signature help (insert mode)
--   [d / ]d previous/next problem · <C-w>d problem under cursor in a float
-- Added here: gd definition · gy type definition · <leader>f format · <leader>i inlay hints
-- Changed here: grr / gri open a picker with a preview instead of the quickfix list

-- Completion menu. Tab/Shift-Tab move through it and Enter accepts (like the old coc setup);
-- <C-space> opens it by hand, <C-e> closes it.
require('blink.cmp').setup({
  keymap = {
    preset = 'enter',
    ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
  },
  appearance = { nerd_font_variant = 'mono' },
  completion = {
    list = { selection = { preselect = false, auto_insert = true } },
    documentation = { auto_show = true, auto_show_delay_ms = 300 },
    menu = vim.g.fancy and {} or { draw = { columns = { { 'label', 'label_description', gap = 1 }, { 'kind' } } } },
  },
  signature = { enabled = true },
  sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
})

-- Every server gets the completion engine's capabilities.
vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })

-- Python: basedpyright for types and go-to, ruff for lint and format.
-- Uses the project's .venv automatically when there is one (e.g. ~/projects/catgpt).
vim.lsp.config('basedpyright', {
  settings = { basedpyright = { analysis = { typeCheckingMode = 'standard' } } },
  before_init = function(_, config)
    local root = config.root_dir
    if root and vim.uv.fs_stat(root .. '/.venv/bin/python') then
      config.settings.python = { pythonPath = root .. '/.venv/bin/python' }
    end
  end,
})

-- Lua: knows about Neovim's API, for editing this config.
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      diagnostics = { globals = { 'vim', 'MiniIcons', 'MiniJump2d', 'Snacks' } },
    },
  },
})

-- Turn on each server whose program is installed. (Rust is handled by rustaceanvim below.)
local servers = {
  basedpyright = 'basedpyright-langserver',
  ruff = 'ruff',
  lua_ls = 'lua-language-server',
  clangd = 'clangd', -- C, C++, CUDA
  glsl_analyzer = 'glsl_analyzer',
}
for name, cmd in pairs(servers) do
  if vim.fn.executable(cmd) == 1 then vim.lsp.enable(name) end
end

-- Rust: rustaceanvim runs rust-analyzer with extras (:RustLsp runnables, expandMacro,
-- explainError, openCargo...). Clippy runs on save.
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ['rust-analyzer'] = {
        imports = { granularity = { group = 'module' } },
        check = { command = 'clippy' },
      },
    },
  },
}

-- Format on save for languages with one standard formatter. <leader>F turns it off/on.
local format_on_save = { rust = true, python = true }

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc }) end

    map('gd', vim.lsp.buf.definition, 'Go to definition')
    map('gy', vim.lsp.buf.type_definition, 'Go to type definition')
    -- In a picker with a preview, instead of the quickfix list.
    map('grr', function() Snacks.picker.lsp_references() end, 'References')
    map('gri', function() Snacks.picker.lsp_implementations() end, 'Implementations')
    map('<leader>f', function() vim.lsp.buf.format({ async = true }) end, 'Format file')
    map('<leader>i', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
    end, 'Toggle inlay hints')
    map('<leader>F', function()
      local ft = vim.bo[ev.buf].filetype
      format_on_save[ft] = not format_on_save[ft]
      vim.notify('Format on save for ' .. ft .. ': ' .. (format_on_save[ft] and 'on' or 'off'))
    end, 'Toggle format on save')

    -- Ruff only lints and formats; leave hover to basedpyright.
    if client.name == 'ruff' then client.server_capabilities.hoverProvider = false end

    -- Python starts with them off: they look too much like real annotations. <leader>i shows them.
    if client:supports_method('textDocument/inlayHint') and vim.bo[ev.buf].filetype ~= 'python' then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(ev)
    if format_on_save[vim.bo[ev.buf].filetype] then
      vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
    end
  end,
})
