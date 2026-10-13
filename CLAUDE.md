# journal.nvim

The journal from inside LazyVim: a which-key `<leader>j` menu, snacks pickers and buffers instead
of a separate TUI. It's for the user only (this Neovim, this machine), so there's no
cross-editor or other-user concern.

This repo lives in the `~/Work/journal` hub as `nvim/`, beside the CLI in `cli/`. The hub's
`CLAUDE.md` has the rules that span both.

## Design rules

- **The `journal` CLI is the app; this plugin is a client of it**, like the `journal-sweep`
  skill. It runs `journal … --json` and renders the result the Neovim way. No journal logic in
  Lua: never parse entry files or frontmatter, and never write into the data folder directly.
  Create with `journal new --json` (text on stdin), change with `journal edit <ref> --stdin --json`.
- **Learn the CLI from the CLI**, `journal docs --all` and `journal docs json`. Don't copy JSON
  shapes into this repo's docs. Refs are an id, `last`, `today` or a unique prefix. Exit codes:
  0 ok, 1 usage, 2 not found, 3 duplicate. Errors come on stderr as `journal: …`.
- **A CLI gap gets fixed in the CLI.** If the plugin needs something the CLI doesn't give (a
  missing JSON field, a missing flag), add it in `~/Work/journal/cli` on its own branch with tests.
  Don't work around it in Lua.
- **All CLI calls go through `lua/journal/cli.lua`**, which runs `vim.system`, decodes the JSON and
  turns a non-zero exit into an error (`vim.notify` at the call site).
- **Journal buffers are `journal://new` and `journal://<id>`** (`buftype=acwrite`, a
  `BufWriteCmd` sends the text to the CLI, `filetype=markdown` so render-markdown applies). They
  set `spellcapcheck=""` and `vim.b.completion = false` themselves. The `journal_no_capcheck`
  autocmd in `~/.config/nvim/lua/config/autocmds.lua` only matches real files, not `journal://`
  names.
- **Prompts and review titles are virtual lines** (extmarks above line 1), never buffer text, so
  they can't be saved by accident. Which prompt to show is the CLI's choice (`prompts pick`).
- **Keymaps live in the plugin** (`setup()` in `lua/journal/init.lua`), under the `<leader>j`
  which-key group. The spec in `~/.config/nvim/lua/plugins/journal.lua` only loads it.

## Layout

```
lua/journal/init.lua      setup(opts), keymaps, which-key group
lua/journal/cli.lua       run `journal` via vim.system, decode JSON, errors
lua/journal/buffers.lua   journal://new, journal://review, journal://<id> buffers; prompt guide
lua/journal/pickers.lua   snacks pickers: entries, search, tags, on this day
lua/journal/read.lua      read-only buffer rendering a stretch of entries; weekly review
tests/                    plenary busted specs, run headless
bin/test                  runs the tests
```

## Tests

`bin/test` (on PATH inside this folder through `~/Work/.mise.toml`) runs every `tests/*_spec.lua`
in headless Neovim with plenary. Each spec points `JOURNAL_DIR` at a fresh temp folder and seeds
it with `journal new --at … --text …`. **Never run tests against the real journal**:
`tests/helpers.lua` refuses to work unless `JOURNAL_DIR` is under the system temp folder.
Specs that expect an error call `helpers.capture_notify()` first: headless Neovim's default
`vim.notify` raises on ERROR, which LazyVim's notifier doesn't.

The tests run the installed `journal`, which is an editable `uv tool` install of `~/Work/journal/cli`:
it runs whatever branch is checked out there. Keep that repo on `main` when not working in it.

## Working here

- Git: GitHub `apodacaa/journal-nvim-plugin` (private). Work lands on `main` through a PR: one
  branch per milestone (`m2-search-tags`, …), push, `gh pr create`. The user decides when to
  merge. Don't commit straight to `main`. A CLI fix goes to the journal repo (`~/Work/journal/cli`,
  GitHub, also PRs) as its own PR, and it merges before the plugin PR that needs it.
- Changes to `~/.config/nvim` are logged in `~/Work/omarchy/changes.md` (newest first, What /
  Why / Undo), via a branch and PR in the omarchy repo.
- Milestones: M0 scaffold; M1 write and find (`<leader>jj`, `<leader>jf`); M2 search, tags, on
  this day (`<leader>js`, `<leader>jt`, `<leader>jo`); M3 reflect (`<leader>jr` read the week,
  `<leader>jp` prompted entry, `<leader>jR` weekly review).
