# journal.nvim

Write, find and reread the `journal` from inside LazyVim. Everything goes through the `journal`
CLI (`journal … --json`). The plugin never reads or writes the data folder itself.

## Install (lazy.nvim, local)

```lua
-- ~/.config/nvim/lua/plugins/journal.lua
return {
  {
    dir = "~/Work/journal.nvim",
    name = "journal.nvim",
    dependencies = { "folke/snacks.nvim" },
    event = "VeryLazy",
    opts = {},
  },
}
```

Options (defaults shown):

```lua
opts = {
  cmd = "journal", -- the journal CLI to run
}
```

Point it at another journal the same way the CLI does, with `JOURNAL_DIR` or
`journal config set storage.dir`.

## Keys

Everything is under the `<leader>j` which-key group "journal".

| Key | Does | Status |
|---|---|---|
| `<leader>jj` | new entry; `:w` saves it | ✓ |
| `<leader>jf` | find an entry (picker with preview) | ✓ |
| `<leader>js` | search text | M2 |
| `<leader>jt` | tags, then their entries | M2 |
| `<leader>jo` | on this day | M2 |
| `<leader>jr` | read the last week | M3 |
| `<leader>jp` | new entry with a writing prompt | M3 |
| `<leader>jR` | weekly review | M3 |

## Journal buffers

An entry opens as `journal://<id>` and a new one as `journal://new`. They're ordinary buffers:
`:w` sends the text to `journal edit <id> --stdin` (or `journal new` for a new one, after which
the buffer is renamed to the new id), and `:e!` reloads from the CLI. You can also
`:e journal://<id>` directly. Only the body is in the buffer, never the frontmatter. Writing an
empty buffer is refused by the CLI and the buffer stays modified. `<leader>jj` returns to an
unsaved `journal://new` draft if there is one.

## Tests

```sh
bin/test            # all specs
bin/test tests/cli_spec.lua
```

They run headless against a temp `JOURNAL_DIR`, never the real journal.
