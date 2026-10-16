-- Rust keys. From the old vimrc: gl = cargo run, gs = cargo test, in a terminal split.
local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = true, desc = desc }) end

map('gl', '<Cmd>write | botright split | terminal cargo run<CR>', 'cargo run')
map('gs', '<Cmd>write | botright split | terminal cargo test<CR>', 'cargo test')

-- rustaceanvim extras
map('<leader>rr', '<Cmd>RustLsp runnables<CR>', 'Pick something to run')
map('<leader>rt', '<Cmd>RustLsp testables<CR>', 'Pick a test to run')
map('<leader>re', '<Cmd>RustLsp explainError current<CR>', 'Explain error')
map('<leader>rd', '<Cmd>RustLsp renderDiagnostic current<CR>', 'Show full compiler error')
map('<leader>rm', '<Cmd>RustLsp expandMacro<CR>', 'Expand macro')
map('<leader>rc', '<Cmd>RustLsp openCargo<CR>', 'Open Cargo.toml')
map('<leader>rp', '<Cmd>RustLsp parentModule<CR>', 'Parent module')
map('J', '<Cmd>RustLsp joinLines<CR>', 'Join lines (Rust-aware)')
