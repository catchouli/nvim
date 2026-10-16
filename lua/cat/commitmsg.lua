-- Commit messages written by Claude. When a commit message opens (,gc, or `git commit`
-- from a shell inside Neovim), Claude Haiku reads the staged diff and writes a message;
-- it appears after about a second, and you edit it or :wq as usual. Typing before it
-- arrives keeps your text. ,gm in the message writes a new one.
--
-- Only for repos that are safe to send to cloud AI: on when the origin remote is on
-- github.com/catchouli, off everywhere else (work code must never be sent). Per repo:
--   git config cat.aicommit true    allow it
--   git config cat.aicommit false   never
--
-- Runs `claude -p` with no tools, no MCP servers, no settings and a short system
-- prompt, so each message costs about as much as the diff itself (big diffs are cut).

local M = {}

local MAX_DIFF = 16000 -- characters of diff sent; about 4k tokens
local SYSTEM = [[You write git commit messages. Reply with only the message, nothing else: a summary
line of at most 72 characters in the imperative mood ("Add ...", "Fix ..."), then, only
if the change needs explaining, a blank line and a short body wrapped at 72 columns
saying what changed and why. Match the style of the recent commit subjects you're shown.
No code fences, no quotes around the message, no trailers.]]

local ns = vim.api.nvim_create_namespace('cat.commitmsg')

local function git(gitdir, args)
  local r = vim.system(vim.list_extend({ 'git', '--git-dir=' .. gitdir }, args), { text = true }):wait()
  return r.code == 0 and r.stdout or nil
end

-- Allowed here? true, or false and why not.
local function allowed(gitdir)
  local setting = vim.trim(git(gitdir, { 'config', '--bool', 'cat.aicommit' }) or '')
  if setting == 'true' then return true end
  if setting == 'false' then return false, 'cat.aicommit is false in this repo' end
  local url = git(gitdir, { 'remote', 'get-url', 'origin' }) or ''
  if url:lower():match('github%.com[:/]catchouli/') then return true end
  return false, "this repo isn't one of yours on GitHub (to allow it: git config cat.aicommit true)"
end

local function prompt(gitdir)
  local stat = git(gitdir, { 'diff', '--cached', '--stat' }) or ''
  if vim.trim(stat) == '' then return nil end
  local diff = git(gitdir, { 'diff', '--cached', '--no-color', '--no-ext-diff', '-U2' }) or ''
  if #diff > MAX_DIFF then
    diff = diff:sub(1, MAX_DIFF) .. '\n[diff cut short: ' .. #diff .. ' characters in all; the stat above lists every file]\n'
  end
  local log = git(gitdir, { 'log', '-n', '8', '--format=%s' }) or ''
  return ('Recent commit subjects:\n%s\nFiles changed:\n%s\nStaged diff:\n%s'):format(log, stat, diff)
end

-- Fills buffer `buf` (a COMMIT_EDITMSG) with a message. `force` replaces what's there.
function M.write(buf, force)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local name = vim.api.nvim_buf_get_name(buf)
  local gitdir = vim.fs.dirname(name)
  local ok, why = allowed(gitdir)
  if not ok then
    if force then vim.notify('No AI commit message: ' .. why, vim.log.levels.WARN) end
    return
  end
  if not force and vim.trim(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or '') ~= '' then
    return -- already has a message (amend, merge, -m ...)
  end
  local claude = vim.fn.exepath('claude')
  if claude == '' then
    if force then vim.notify('No AI commit message: claude is not on the PATH', vim.log.levels.WARN) end
    return
  end
  local input = prompt(gitdir)
  if not input then
    if force then vim.notify('Nothing is staged', vim.log.levels.WARN) end
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local mark = vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    virt_text = { { 'Claude is writing a message…', 'Comment' } }, virt_text_pos = 'eol',
  })
  local before = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  vim.system({
    claude, '-p', '--model', 'haiku', '--tools', '', '--strict-mcp-config', '--setting-sources', '',
    '--no-session-persistence', '--disable-slash-commands', '--system-prompt', SYSTEM,
    -- Run outside the repo: while git commit waits for the message it holds the repo's
  -- lock, and Claude Code's own git checks at startup would wait on it.
}, { stdin = input, text = true, timeout = 30000, cwd = vim.fn.stdpath('cache') }, vim.schedule_wrap(function(r)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    pcall(vim.api.nvim_buf_del_extmark, buf, ns, mark)
    local msg = vim.trim(r.stdout or '')
    if r.code ~= 0 or msg == '' then
      vim.notify('No AI commit message: ' .. vim.trim(r.stderr or 'claude failed'), vim.log.levels.WARN)
      return
    end
    -- Typed something meanwhile? Keep it. (Compares the text: the change counter moves
    -- on its own while the commit buffer is being set up.)
    if vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] ~= before then return end
    local lines = vim.split((msg:gsub('^```%w*\n', ''):gsub('\n```$', '')), '\n')
    if force then
      -- Replace the old message, keeping git's comment lines below it.
      local all = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local first_comment = #all
      for i, l in ipairs(all) do
        if l:match('^#') then first_comment = i - 1; break end
      end
      vim.api.nvim_buf_set_lines(buf, 0, first_comment, false, vim.list_extend(lines, { '' }))
    else
      vim.api.nvim_buf_set_lines(buf, 0, 1, false, lines)
    end
  end))
end

function M.setup()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'gitcommit',
    callback = function(ev)
      if vim.fs.basename(vim.api.nvim_buf_get_name(ev.buf)) ~= 'COMMIT_EDITMSG' then return end
      vim.keymap.set('n', '<leader>gm', function() M.write(ev.buf, true) end,
        { buffer = ev.buf, desc = 'Write a new commit message (Claude)' })
      M.write(ev.buf, false)
    end,
  })
end

return M
