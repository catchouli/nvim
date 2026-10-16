-- Finding things, git and GitHub, tests, Claude Code.
local map = vim.keymap.set

-- snacks.nvim: fuzzy finder, start screen, notifications, indent guides, GitHub.
require('snacks').setup({
  picker = {
    enabled = true,
    sources = {
      -- Ctrl-P: open buffers, then recent files and all files, but only from this folder
      -- (recent files are otherwise Neovim's whole history, from every project).
      -- ,o still shows recent files from everywhere.
      smart = { multi = { 'buffers', { source = 'recent', filter = { cwd = true } }, 'files' } },
    },
  },
  dashboard = { -- start screen when you run nvim with no file
    enabled = true,
    preset = {
      -- Each line is centred on its own, so they're all padded to the same width.
      header = table.concat({
        [[    /\_/\    ]],
        [[   ( o.o )   ]],
        [[    > ^ <    ]],
        [[             ]],
        [[ n e o v i m ]],
      }, '\n'),
      keys = {
        { key = 'f', desc = 'Find file', action = ':lua Snacks.picker.smart()' },
        { key = 'g', desc = 'Search text', action = ':lua Snacks.picker.grep()' },
        { key = 'r', desc = 'Recent files', action = ':lua Snacks.picker.recent()' },
        { key = 'n', desc = 'New file', action = ':enew | startinsert' },
        { key = 'p', desc = 'GitHub pull requests', action = ':lua Snacks.picker.gh_pr()' },
        { key = 'c', desc = 'Edit this config', action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
        { key = 'u', desc = 'Update plugins', action = ':lua vim.pack.update()' },
        { key = '?', desc = 'Cheat sheet', action = function() _G.cat_cheatsheet() end },
        { key = 'q', desc = 'Quit', action = ':qa' },
      },
    },
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      { section = 'recent_files', title = 'Recent files', cwd = true, limit = 6, indent = 2, padding = 1 },
    },
  },
  notifier = { enabled = true }, -- tidy pop-up messages, and LSP progress
  indent = { enabled = true }, -- indent guides, current scope highlighted
  input = { enabled = true }, -- nicer prompt for rename etc.
  words = { enabled = true }, -- highlights other uses of the word under the cursor; ]] / [[ jump between them
  bigfile = { enabled = true }, -- turns heavy features off for huge files
  quickfile = { enabled = true }, -- shows a file opened from the shell before plugins finish loading
  gh = { enabled = true }, -- GitHub issues and PRs, through the gh CLI
})

-- Back to the start screen, and the cheat sheet (CHEATSHEET.md in this folder).
function _G.cat_cheatsheet()
  Snacks.win({
    file = vim.fn.stdpath('config') .. '/CHEATSHEET.md',
    width = 0.8,
    height = 0.85,
    border = 'rounded',
    title = ' Cheat sheet ',
    title_pos = 'center',
    wo = { conceallevel = 2, wrap = false, spell = false, number = false, relativenumber = false, signcolumn = 'no' },
    bo = { modifiable = false, readonly = true },
    keys = { q = 'close' },
  })
end
vim.api.nvim_create_user_command('Home', function() Snacks.dashboard() end, { desc = 'Start screen' })
map('n', '<leader>m', function() Snacks.dashboard() end, { desc = 'Start screen' })
map('n', '<leader>?', _G.cat_cheatsheet, { desc = 'Cheat sheet' })

-- Finding things (CtrlP and friends). In any picker: <C-j>/<C-k> or arrows to move,
-- <CR> open, <C-v>/<C-s> open in a split, <Tab> mark several, <Esc> close, ? for help.
local P = function(name, opts) return function() Snacks.picker[name](opts) end end
map('n', '<C-p>', P('smart'), { desc = 'Find file (recent and project)' })
map('n', '<leader>p', P('files'), { desc = 'Find file in project' })
map('n', '<leader>/', P('grep'), { desc = 'Search text in project' })
map({ 'n', 'x' }, '<leader>*', P('grep_word'), { desc = 'Search word/selection in project' })
map('n', '<leader>b', P('buffers'), { desc = 'Open buffers' })
map('n', '<leader>o', P('recent'), { desc = 'Recent files' })
map('n', '<leader>s', P('lsp_symbols'), { desc = 'Symbols in file' })
map('n', '<leader>S', P('lsp_workspace_symbols'), { desc = 'Symbols in project' })
map('n', '<leader>d', P('diagnostics'), { desc = 'Problems in project' })
map('n', '<leader>h', P('help'), { desc = 'Search help' })
map('n', '<leader>k', P('keymaps'), { desc = 'Search keymaps' })
map('n', '<leader>.', P('resume'), { desc = 'Reopen last picker' })
map('n', '<leader>n', function() Snacks.notifier.show_history() end, { desc = 'Message history' })
map('n', ']]', function() Snacks.words.jump(vim.v.count1) end, { desc = 'Next use of this word' })
map('n', '[[', function() Snacks.words.jump(-vim.v.count1) end, { desc = 'Previous use of this word' })

-- Folders (oil.nvim): `nvim .` or - shows a folder as a buffer filling the window.
-- Enter opens a file or folder, - goes up, _ goes to the project root. Edit the listing
-- like text (rename a line, dd to delete, o for a new file, end with / for a folder),
-- then :w to apply. Deleted files go to the bin. g? lists its keys.
require('oil').setup({
  default_file_explorer = true,
  columns = vim.g.fancy and { 'icon' } or {},
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  watch_for_changes = true,
  view_options = { show_hidden = true },
  keymaps = {
    -- Keep <C-h>/<C-l> for moving between windows and <C-p> for the finder.
    ['<C-h>'] = false,
    ['<C-l>'] = false,
    ['<C-p>'] = false,
    ['<C-x>'] = { 'actions.select', opts = { horizontal = true } },
    ['<C-v>'] = { 'actions.select', opts = { vertical = true } },
    ['gp'] = 'actions.preview',
    ['R'] = 'actions.refresh',
    ['q'] = { 'actions.close', mode = 'n' },
  },
})
map('n', '-', '<Cmd>Oil<CR>', { desc = "Open this file's folder" })

-- Git: changed lines in the sign column, :Git for any git command.
require('mini.diff').setup()
require('mini.git').setup()
require('cat.commitmsg').setup() -- Claude writes the message when a commit opens
map('n', '<leader>gs', P('git_status'), { desc = 'Git status' })
map('n', '<leader>gd', P('git_diff'), { desc = 'Git diff (changed hunks)' })
map('n', '<leader>gl', P('git_log_file'), { desc = 'Git log of this file' })
map('n', '<leader>gL', P('git_log'), { desc = 'Git log' })
map('n', '<leader>gb', P('git_branches'), { desc = 'Git branches' })
map('n', '<leader>go', function() MiniDiff.toggle_overlay(0) end, { desc = 'Show changes inline' })
map('n', '<leader>gB', function() Snacks.gitbrowse() end, { desc = 'Open on GitHub' })
-- ]h / [h jump between changed hunks; gh / gH apply / reset a hunk (mini.diff).
-- Alt+j / Alt+k do the same as ]h / [h without reaching for the brackets (left Option is
-- Alt in Ghostty).
map({ 'n', 'x' }, '<M-j>', function() MiniDiff.goto_hunk('next') end, { desc = 'Next change' })
map({ 'n', 'x' }, '<M-k>', function() MiniDiff.goto_hunk('prev') end, { desc = 'Previous change' })

-- Reviewing changes (diffview): a tab with every changed file down the left and the
-- selected one side by side. Staging a file (-) marks it reviewed; what's left unstaged
-- is what's still to read. g? lists the keys. cc commits what's staged (mini.git opens
-- the message in a tab: :wq commits, :q! cancels).
local commit = { 'n', 'cc', '<Cmd>Git commit<CR>', { desc = 'Commit the staged changes' } }
require('diffview').setup({
  enhanced_diff_hl = true,
  keymaps = { file_panel = { commit } }, -- the file list only: in the diffs cc still edits
})
map('n', '<leader>gv', function()
  if require('diffview.lib').get_current_view() then vim.cmd('DiffviewClose') else vim.cmd('DiffviewOpen') end
end, { desc = 'Review changes (toggle)' })
map('n', '<leader>gq', '<Cmd>DiffviewClose<CR>', { desc = 'Close the review' })
map('n', '<leader>gc', '<Cmd>Git commit<CR>', { desc = 'Commit the staged changes' })
map('n', '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', { desc = 'History of this file, side by side' })
map('n', '<leader>gH', '<Cmd>DiffviewFileHistory<CR>', { desc = 'History of the repo, side by side' })

-- GitHub, via your gh login. <CR> on a PR or issue shows its actions: view diff,
-- comment, review (approve / request changes), checkout, merge, open in browser.
map('n', '<leader>gp', P('gh_pr'), { desc = 'GitHub pull requests (open)' })
map('n', '<leader>gP', P('gh_pr', { state = 'all' }), { desc = 'GitHub pull requests (all)' })
map('n', '<leader>gi', P('gh_issue'), { desc = 'GitHub issues (open)' })
map('n', '<leader>gI', P('gh_issue', { state = 'all' }), { desc = 'GitHub issues (all)' })

-- Tests (neotest): pytest and cargo test. Set up on first use so startup stays fast.
-- Pass/fail marks appear in the sign column; failures show inline.
local tests_ready = false
local function neotest()
  if not tests_ready then
    require('neotest').setup({
      adapters = {
        require('neotest-python'),
        require('rustaceanvim.neotest'),
      },
    })
    tests_ready = true
  end
  return require('neotest')
end
map('n', '<leader>tt', function() neotest().run.run() end, { desc = 'Run nearest test' })
map('n', '<leader>tf', function() neotest().run.run(vim.fn.expand('%')) end, { desc = 'Run tests in file' })
map('n', '<leader>ta', function() neotest().run.run(vim.uv.cwd()) end, { desc = 'Run all tests' })
map('n', '<leader>tl', function() neotest().run.run_last() end, { desc = 'Run last test again' })
map('n', '<leader>ts', function() neotest().summary.toggle() end, { desc = 'Test summary panel' })
map('n', '<leader>to', function() neotest().output.open({ enter = true }) end, { desc = 'Test output' })
map('n', '<leader>tw', function() neotest().watch.toggle(vim.fn.expand('%')) end, { desc = 'Rerun file tests on save' })

-- Rust's Cargo.toml: latest versions and features shown inline, completion for them.
require('crates').setup({ lsp = { enabled = true, actions = true, completion = true, hover = true } })

-- Claude Code: runs `claude` in a split on the right. It sees your open file and
-- selection, and its edits arrive as diffs here to accept or reject.
-- Already running claude in another terminal? Type /ide in it to connect to this Neovim.
require('claudecode').setup({
  terminal = {
    split_side = 'right', split_width_percentage = 0.4, provider = 'snacks',
    -- Esc and Esc Esc go to Claude (stop it / go back to an earlier message) instead of
    -- leaving terminal mode. Ctrl-h jumps back to your file; Ctrl-\ Ctrl-n leaves
    -- terminal mode without moving.
    -- (Snacks treats a plain '<Esc>' here as one of its own actions, so send the byte.)
    snacks_win_opts = { keys = {
      term_normal = false,
      claude_esc = { '<Esc>', function() vim.api.nvim_chan_send(vim.b.terminal_job_id, '\27') end, mode = 't', desc = 'Esc to Claude' },
    } },
  },
})
map('n', '<leader>ac', '<Cmd>ClaudeCode<CR>', { desc = 'Toggle Claude' })
map('n', '<leader>af', '<Cmd>ClaudeCodeFocus<CR>', { desc = 'Focus Claude' })
map('n', '<leader>ar', '<Cmd>ClaudeCode --resume<CR>', { desc = 'Resume a Claude session' })
map('n', '<leader>ab', '<Cmd>ClaudeCodeAdd %<CR>', { desc = 'Add this file to Claude' })
map('x', '<leader>as', '<Cmd>ClaudeCodeSend<CR>', { desc = 'Send selection to Claude' })
map('n', '<leader>aa', '<Cmd>ClaudeCodeDiffAccept<CR>', { desc = "Accept Claude's change" })
map('n', '<leader>ad', '<Cmd>ClaudeCodeDiffDeny<CR>', { desc = "Reject Claude's change" })
