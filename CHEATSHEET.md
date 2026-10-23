# Cheat sheet

Keys for the plugins and newer Neovim features in this config. Open it with `?` on the start screen or `,?` anywhere; `q` closes it. Back to the start screen: `,m` (or `:Home`).

Leader is `,`. **Press `,` (or `g`, `z`, `[`, `]`, `<C-w>`, `"`) and wait: a popup lists what comes next.** `,k` searches every key.

**Finding things**

| Key | Does |
|---|---|
| `<C-p>` | find a file in the current folder (open and recent ones first) |
| `,p` / `,o` / `,b` | project files / recent files / open buffers |
| `,/` | search text in the project (ripgrep) |
| `,*` | search for the word under the cursor (or the selection) |
| `,s` / `,S` | symbols in this file / in the project |
| `,d` | all problems in the project |
| `,h` / `,k` | search help / keymaps |
| `,.` | reopen the last search where you left it |
| `-` | this file's folder as a buffer (also `nvim .`); see **Folders** below |
| `,M` | minimap on/off (it also hides itself when the code would be under 100 columns wide) |

In any picker: type to filter, `<C-j>`/`<C-k>` to move, Enter to open, `<C-v>`/`<C-s>` to open in a split, `<Tab>` to select several, `?` for its own help.

**Folders** (oil: `nvim .`, or `-` from a file)

| Key | Does |
|---|---|
| `<CR>` / `-` / `_` | open file or folder / up a folder / project root |
| edit the text, then `:w` | rename a line to rename the file, `dd` to delete (goes to the bin), `o` + `name` for a new file, `name/` for a folder; copy and move with `yy`/`dd` + `p` |
| `<C-v>` / `<C-x>` / `<C-t>` | open in a vertical split / horizontal split / new tab |
| `gp` / `R` / `g.` | preview / refresh / show or hide dotfiles |
| `q` / `g?` | close / all its keys |

**Moving and editing**

| Key | Does |
|---|---|
| `,,` then a character | jump to it on screen: labels appear, type one (EasyMotion) |
| `saiw)` / `sd"` / `sr)]` | surround: add () round a word / delete quotes / change () to [] |
| `cia` `daf` `viq` | text objects: argument (`a`), function call (`f`), quotes (`q`), brackets (`b`)... |
| `gc` / `gcc` | comment a selection / line (built into Neovim) |
| `J` / `K` in visual mode | move the selected lines down / up |
| `,y` | yank to the system clipboard (`<S-Insert>` pastes in insert mode) |
| `<C-h/j/k/l>` | move between windows (`<C-h>`/`<C-l>` also work from inside a terminal or Claude) |
| `<CR>` | clear search highlight |

**Code (any language with a server)**

| Key | Does |
|---|---|
| `K` | docs for the thing under the cursor |
| `gd` / `gy` | go to definition / type definition |
| `grr` / `gri` | references / implementations, in a picker with a preview |
| `grn` / `gra` | rename / code actions (fixes, imports...) |
| `[d` / `]d`, `,e` | previous / next problem; show the problem under the cursor |
| `,f` / `,F` | format now / toggle format-on-save (on for Rust and Python) |
| `,i` | toggle inlay hints (types shown inline; off at first in Python) |
| `]]` / `[[` | next / previous use of the word under the cursor |
| Insert mode | completion pops up as you type: `<Tab>`/`<S-Tab>` choose, Enter accepts, `<C-space>` opens it, `<C-e>` closes, `<C-s>` signature help |

**Rust**

| Key | Does |
|---|---|
| `gl` / `gs` | save, then `cargo run` / `cargo test` in a split |
| `,rr` / `,rt` | pick something to run / a test to run |
| `,re` / `,rd` | explain the error / show the full compiler message |
| `,rm` / `,rc` / `,rp` | expand a macro / open Cargo.toml / go to the parent module |
| In Cargo.toml | latest versions shown inline; `K` on a crate shows its info |

Clippy runs on save. Python uses the project's `.venv` automatically.

**Tests** (pytest and cargo test, via neotest)

| Key | Does |
|---|---|
| `,tt` / `,tf` / `,ta` | run the nearest test / this file's / all |
| `,tl` | run the last test again |
| `,ts` / `,to` | summary panel / output of the test under the cursor |
| `,tw` | rerun this file's tests whenever it's saved |

**Git and GitHub**

| Key | Does |
|---|---|
| sign column | changed lines; `Alt+j`/`Alt+k` (or `]h`/`[h`) next/previous change; `ghgh` stages the change under the cursor, `gHgh` undoes it (`gh`/`gH` also work on a selection) |
| `,gv` | **review changes**: every changed file down the left, the selected one side by side (`,gv` again or `,gq` closes) |
| in the review | `Tab`/`S-Tab` next/previous file, `-` stage or unstage a file, `S` stage all, `U` unstage all, `X` throw away a file's changes, `cc` (in the file list) or `,gc` commit, `g?` all keys |
| in the file list | `Ctrl-J`/`Ctrl-K` scroll the diff without leaving the list (`Ctrl-F`/`Ctrl-B` scroll further); `gf` opens the file in your normal tab |
| `,gc` | commit what's staged: the message opens in a tab, and in your own repos Claude fills it in after a second or two; tweak it, then `:wq` commits, `:q!` cancels |
| `,gm` | in a commit message or pull request: have Claude write a new one |
| `,gh` / `,gH` | history of this file / of the repo, each commit side by side |
| `,go` | show the changes inline, with the old text |
| `,gs` / `,gd` / `,gb` | git status / changed hunks / branches |
| `,gu` | pull the current branch (e.g. `,gb` to `main` after a PR is merged, then `,gu`) |
| `,gl` / `,gL` | history of this file / of the repo |
| `,gB` | open this file on GitHub |
| `:Git …` | any git command, output in a split |
| `,gp` / `,gP` | GitHub pull requests: open / all |
| `,gr` | pull request from this branch into the default branch: it opens in a tab like a commit message, Claude drafts it (first line is the title), and the comments under it say where it's going and warn about anything off (uncommitted changes, a push that would be refused). `:wq` pushes the branch and creates it; empty or `:q!` cancels. If it fails, `,gr` again brings your text back |
| `,gi` / `,gI` | GitHub issues: open / all |

Reviewing a lot of AI-written changes: open `,gv`, go file by file, and stage each file (`-`) or change once you're happy with it. For a single change, use `ghgh` in the right-hand pane of an unstaged file: that pane is the real file, while the left-hand pane and staged files are read-only copies where `ghgh` doesn't work. Whatever's still unstaged is what's left to read, and anything the agent changes afterwards shows up unstaged again. Commit with `,gc` (or `cc` in the file list) when you're done; Claude drafts the message for you to tweak.

AI commit messages and pull requests only happen in repos whose `origin` is on one of your GitHub accounts (`OWNERS` at the top of `lua/cat/commitmsg.lua`), so work code is never sent. To allow another repo: `git config cat.aicommit true`; to turn it off in one: `git config cat.aicommit false`. Each message uses Claude Haiku with no tools, and costs about as many tokens as the diff (big diffs are cut to about 4k tokens).

On a PR or issue, Enter shows the actions: view the diff, comment, review (approve or request changes), check out the branch, merge, open in the browser. It uses your `gh` login.

**Claude Code**

| Key | Does |
|---|---|
| `,ac` | open or close Claude in a split on the right |
| `,af` / `,ar` | jump to Claude / resume an earlier session |
| `,al` | Claude's split looks messed up or scrolled? Redraw it and scroll to the bottom |
| in Claude | `<C-h>` back to your file, `<C-l>` back into Claude (ready to type); `Esc` / `Esc Esc` go to Claude (stop it / go back to an earlier message); `<C-\><C-n>` leaves typing mode without moving |
| `,ab` | add this file to the conversation |
| `,as` (visual) | send the selection |
| `,aa` / `,ad` | accept / reject the change Claude proposed (shown as a diff) |

Claude sees which file you're in and what you've selected. Already running `claude` in another terminal? Type `/ide` there to connect it to this Neovim.

**Terminal**: `:terminal`, and `<Esc>` gets back to normal mode (except in Claude's split, see above).

**Start screen**: `,m` or `:Home` to get back to it; `f` `g` `r` `n` `p` `c` `u` `q` as listed on it; `?` for this sheet.

**Messages**: `,n` shows earlier pop-up messages (errors, LSP progress).

## New in Neovim since the old vimrc

| What | Notes |
|---|---|
| `gc` / `gcc` | comment toggling is built in now |
| `grn` `gra` `grr` `gri` `grt` `gO` `K` | LSP keys are built in (see Code above); no coc |
| `[d` `]d` `<C-w>d` | diagnostics navigation is built in |
| `[q` `]q` `[b` `]b` `[<Space>` `]<Space>` | quickfix / buffer next and previous; add a blank line above / below |
| `:restart` | restart Neovim keeping your windows (0.12); use after changing the config |
| `:checkhealth` | what's installed, what's missing |
| `:Inspect` | which highlight groups and syntax nodes are under the cursor |
| `:lua vim.pack.update()` | update plugins: read the changes, `:write` to apply, `:quit` to skip |
| `:checkhealth vim.lsp` | which language servers are attached, and why not |
| Persistent undo | undo history survives closing a file |
| `:TSInstall <lang>` | add a syntax parser for another language |
