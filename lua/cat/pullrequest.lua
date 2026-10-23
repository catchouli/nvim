-- Pull requests (,gr): opens a pull request from the current branch into the repo's
-- default branch on GitHub. A window opens like a commit message's, and in the repos
-- where Claude writes commit messages (see commitmsg.lua) it writes the title and
-- description too. First line: title; the rest: description (markdown). Save it (:wq)
-- to push the branch and create the pull request; leave it empty, or :q!, to cancel.
-- ,gm in the window writes a new one.
--
-- Under the scissors line the window says where the pull request will go, which commits
-- it has, what the push will do, and warns about anything that looks wrong (changes that
-- aren't committed, a push that will be refused). None of that is sent.
--
-- If the push or gh fails, the text is kept: ,gr again opens it instead of a new draft.

local M = {}

local commitmsg = require('cat.commitmsg')

local MAX_DIFF = 16000 -- characters of diff sent; about 4k tokens
local SCISSORS = '# ------------------------ >8 ------------------------'
local SYSTEM = [[You write GitHub pull request titles and descriptions. Reply with only the pull
request, nothing else: the title on the first line (at most 72 characters, like a
commit summary: "Add ...", "Fix ..."), then a blank line and a short markdown
description of what the branch changes and why, for a reviewer. A sentence or two for a
small change; a few bullets if there are several separate changes. No headings, no
code fences around the reply, no closing remarks.]]

local ns = vim.api.nvim_create_namespace('cat.pullrequest')
local drafts = {} -- text kept after a failed attempt, by repo and branch

-- Runs a command and waits for it without blocking Neovim; call inside a coroutine.
-- Returns stdout (trimmed) on success, or nil and the error output.
local function run(cmd, cwd, stdin)
  local co = coroutine.running()
  vim.system(cmd, { cwd = cwd, stdin = stdin, text = true }, function(r)
    vim.schedule(function()
      local ok, err = coroutine.resume(co, r)
      if not ok then vim.notify(debug.traceback(co, err), vim.log.levels.ERROR) end
    end)
  end)
  local r = coroutine.yield()
  if r.code ~= 0 then return nil, vim.trim((r.stderr or '') .. '\n' .. (r.stdout or '')) end
  return vim.trim(r.stdout or '')
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { id = 'pull_request', title = 'Pull request' })
end

local function count(n, one, many) return n .. ' ' .. (n == 1 and one or many) end

-- Everything ,gr needs to know before opening the window, or nil and why not.
local function gather(root)
  local branch = run({ 'git', 'symbolic-ref', '--short', 'HEAD' }, root)
  if not branch then return nil, "You're not on a branch (detached HEAD)" end

  local repo, err = run({ 'gh', 'repo', 'view', '--json', 'nameWithOwner,defaultBranchRef',
    '-q', '.nameWithOwner + " " + .defaultBranchRef.name' }, root)
  if not repo then return nil, 'gh repo view failed:\n' .. err end
  local name, base = repo:match('^(%S+) (%S+)$')
  if branch == base then
    return nil, ("You're on %s, the default branch. Make a branch for the pull request first (,gb, or :Git switch -c name)"):format(base)
  end

  -- Fresh copies of the remote branches, so the commit list and push check are right.
  run({ 'git', 'fetch', '--quiet', 'origin' }, root)
  local base_ref = run({ 'git', 'rev-parse', '--verify', '--quiet', 'refs/remotes/origin/' .. base }, root)
    and 'origin/' .. base or base

  local commits = run({ 'git', 'log', '--format=%h %s', base_ref .. '..HEAD' }, root) or ''
  if commits == '' then return nil, ('%s has no commits that %s doesn\'t have'):format(branch, base) end

  local i = {
    root = root, branch = branch, base = base, base_ref = base_ref, repo = name,
    gitdir = run({ 'git', 'rev-parse', '--absolute-git-dir' }, root),
    commits = vim.split(commits, '\n'),
    stat = run({ 'git', 'diff', '--stat', base_ref .. '...HEAD' }, root) or '',
    warnings = {},
  }

  -- Is there a pull request for this branch already?
  local prs = run({ 'gh', 'pr', 'list', '--head', branch, '--state', 'all', '--limit', '1',
    '--json', 'url,state', '-q', '.[] | .state + " " + .url' }, root) or ''
  local state, url = prs:match('^(%S+) (%S+)$')
  if state == 'OPEN' then i.open_pr = url
  elseif state then table.insert(i.warnings, ('An earlier pull request from %s was %s: %s'):format(branch, state:lower(), url)) end

  -- What the push will do.
  local remote = 'origin/' .. branch
  if not run({ 'git', 'rev-parse', '--verify', '--quiet', 'refs/remotes/' .. remote }, root) then
    i.push = ('Pushes %s to origin (a new branch there).'):format(branch)
  else
    local ahead = tonumber(run({ 'git', 'rev-list', '--count', remote .. '..HEAD' }, root)) or 0
    local behind = tonumber(run({ 'git', 'rev-list', '--count', 'HEAD..' .. remote }, root)) or 0
    i.push = ahead > 0 and ('Pushes %s to %s.'):format(count(ahead, 'commit', 'commits'), remote)
      or ('%s is already up to date.'):format(remote)
    if behind > 0 then
      table.insert(i.warnings, ("%s has %s that you don't, so the push will be refused. Pull first (,gu)."):format(
        remote, count(behind, 'commit', 'commits')))
    end
  end

  -- Work that won't be in it.
  local changed, untracked = 0, 0
  for _, l in ipairs(vim.split(run({ 'git', 'status', '--porcelain' }, root) or '', '\n', { trimempty = true })) do
    if l:match('^%?%?') then untracked = untracked + 1 else changed = changed + 1 end
  end
  if changed > 0 then
    table.insert(i.warnings, ("%s changes that aren't committed; they won't be in the pull request."):format(
      count(changed, 'file has', 'files have')))
  end
  if untracked > 0 then
    table.insert(i.warnings, ("%s that git isn't tracking (not in the pull request)."):format(
      count(untracked, 'new file', 'new files')))
  end
  return i
end

-- The comment lines under the scissors.
local function comments(i)
  local c = {
    SCISSORS,
    '# Everything from the line above down is left out of the pull request.',
    '# First line: title. The rest: description (markdown). Empty, or :q!, to cancel.',
    '#',
    ('# :wq opens a pull request on %s:'):format(i.repo),
    ('#     %s  →  %s'):format(i.branch, i.base),
    '# ' .. i.push,
  }
  if #i.warnings > 0 then
    table.insert(c, '#')
    for _, w in ipairs(i.warnings) do table.insert(c, '# ⚠ ' .. w) end
  end
  table.insert(c, '#')
  table.insert(c, ('# %s:'):format(count(#i.commits, 'commit', 'commits')))
  for n, l in ipairs(i.commits) do
    if n > 20 then table.insert(c, ('#   … and %d more'):format(#i.commits - 20)); break end
    table.insert(c, '#   ' .. l)
  end
  if i.stat ~= '' then
    table.insert(c, '#')
    for _, l in ipairs(vim.split(i.stat, '\n')) do table.insert(c, '#   ' .. vim.trim(l)) end
  end
  return c
end

local function prompt(i)
  local log = run({ 'git', 'log', '--reverse', '--format=%s%n%n%b', i.base_ref .. '..HEAD' }, i.root) or ''
  local diff = run({ 'git', 'diff', '--no-color', '--no-ext-diff', '-U2', i.base_ref .. '...HEAD' }, i.root) or ''
  if #diff > MAX_DIFF then
    diff = diff:sub(1, MAX_DIFF) .. '\n[diff cut short: ' .. #diff .. ' characters in all; the stat above lists every file]\n'
  end
  return ('Branch %s, into %s.\n\nCommits, oldest first:\n%s\n\nFiles changed:\n%s\n\nDiff:\n%s'):format(
    i.branch, i.base, log, i.stat, diff)
end

-- Splits the window's text into title and description, leaving out the comments.
local function parse(lines)
  local text = {}
  for _, l in ipairs(lines) do
    if l == SCISSORS then break end
    table.insert(text, l)
  end
  while text[1] and vim.trim(text[1]) == '' do table.remove(text, 1) end
  if not text[1] then return nil end
  local title = vim.trim(table.remove(text, 1))
  return title, vim.trim(table.concat(text, '\n')), text
end

local function create(i, title, body, lines)
  local key = i.root .. '\0' .. i.branch
  local function failed(what, err)
    drafts[key] = lines
    notify(what .. ':\n' .. err .. '\n\nYour text is kept: ,gr opens it again.', vim.log.levels.ERROR)
  end
  coroutine.wrap(function()
    notify('Pushing ' .. i.branch .. '…')
    local _, err = run({ 'git', 'push', '-u', 'origin', 'HEAD' }, i.root)
    if err then return failed('Push failed', err) end
    notify('Creating the pull request…')
    local url, err2 = run({ 'gh', 'pr', 'create', '--base', i.base, '--head', i.branch,
      '--title', title, '--body-file', '-' }, i.root, body)
    if not url then return failed("Couldn't create the pull request", err2) end
    drafts[key] = nil
    notify('Pull request created:\n' .. url:match('[^\n]*$'))
  end)()
end

-- Opens the pull request window for the current branch.
function M.open()
  local root = vim.fs.root(0, '.git') or vim.fs.root(vim.fn.getcwd(), '.git')
  if not root then return notify('Not in a git repo', vim.log.levels.WARN) end
  coroutine.wrap(function()
    notify('Getting the pull request ready…')
    local i, why = gather(root)
    if not i then return notify(why, vim.log.levels.WARN) end
    Snacks.notifier.hide('pull_request')
    if i.open_pr then
      vim.ui.select({ 'Open it in the browser', 'Cancel' }, {
        prompt = ('%s already has an open pull request: %s'):format(i.branch, i.open_pr),
      }, function(choice)
        if choice == 'Open it in the browser' then vim.ui.open(i.open_pr) end
      end)
      return
    end

    vim.cmd.tabnew()
    local buf = vim.api.nvim_get_current_buf()
    local name = i.root .. '/PULL_REQUEST (' .. i.branch .. ')'
    local old = vim.fn.bufnr(name)
    if old ~= -1 then vim.api.nvim_buf_delete(old, { force = true }) end
    vim.api.nvim_buf_set_name(buf, name)
    vim.bo[buf].buftype = 'acwrite'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = 'markdown'

    local key = i.root .. '\0' .. i.branch
    local text = vim.list_extend(vim.deepcopy(drafts[key] or { '' }), { '' })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.list_extend(vim.deepcopy(text), comments(i)))
    vim.api.nvim_buf_set_extmark(buf, ns, #text, 0, { -- the comments, greyed out
      end_row = vim.api.nvim_buf_line_count(buf), hl_group = 'Comment', hl_eol = true, priority = 200,
    })
    vim.bo[buf].modified = false
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local function draft(force)
      local ok, why_not = commitmsg.allowed(i.gitdir)
      if not ok then
        if force then vim.notify('No AI pull request: ' .. why_not, vim.log.levels.WARN) end
        return
      end
      coroutine.wrap(function()
        local input = prompt(i)
        if not vim.api.nvim_buf_is_valid(buf) then return end
        commitmsg.fill(buf, SYSTEM, input, force, '^' .. vim.pesc(SCISSORS) .. '$', 'pull request')
      end)()
    end
    vim.keymap.set('n', '<leader>gm', function() draft(true) end, { buffer = buf, desc = 'Write a new pull request (Claude)' })
    if not drafts[key] then draft(false) end

    -- Saving creates it, then the window closes (:w as well as :wq, so it can't be sent twice).
    vim.api.nvim_create_autocmd('BufWriteCmd', {
      buffer = buf,
      callback = function()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        vim.bo[buf].modified = false
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
        end)
        local title, desc, text_lines = parse(lines)
        if not title then return notify('Empty, so no pull request.', vim.log.levels.WARN) end
        create(i, title, desc, vim.list_extend({ title }, text_lines))
      end,
    })
  end)()
end

return M
