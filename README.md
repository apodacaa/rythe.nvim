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
| `<leader>jj` | new entry; `:w` saves it | M1 |
| `<leader>jf` | find an entry (picker with preview) | M1 |
| `<leader>js` | search text | M2 |
| `<leader>jt` | tags, then their entries | M2 |
| `<leader>jo` | on this day | M2 |
| `<leader>jr` | read the last week | M3 |
| `<leader>jp` | new entry with a writing prompt | M3 |
| `<leader>jR` | weekly review | M3 |

## Tests

```sh
bin/test            # all specs
bin/test tests/cli_spec.lua
```

They run headless against a temp `JOURNAL_DIR`, never the real journal.
