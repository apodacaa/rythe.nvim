# rythe.nvim

Write, find and reread your journal from inside Neovim (built for LazyVim). Everything goes
through the `rythe` CLI (`rythe … --json`). The plugin never reads or writes the data folder itself.

[CHANGELOG.md](CHANGELOG.md) lists what changed in each version.

## Requirements

- Neovim 0.10 or later.
- The [`rythe`](https://github.com/apodacaa/rythe) CLI, 0.2.0 or later, on your PATH. The
  plugin is only a view of it: the CLI is the journal, and it is not installed with the plugin.
  With [uv](https://docs.astral.sh/uv/):

  ```
  uv tool install git+https://github.com/apodacaa/rythe
  ```

- [snacks.nvim](https://github.com/folke/snacks.nvim) with its picker enabled, for finding,
  searching and tags. LazyVim has it already.
- Optional: [which-key.nvim](https://github.com/folke/which-key.nvim) names the `<leader>j` group,
  and a markdown renderer such as render-markdown.nvim styles the entries, which are markdown
  buffers.

Without the CLI every key answers "the rythe CLI isn't installed".

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
-- ~/.config/nvim/lua/plugins/rythe.lua
return {
  {
    "apodacaa/rythe.nvim",
    dependencies = { "folke/snacks.nvim" },
    event = "VeryLazy",
    opts = {},
  },
}
```

To work on the plugin from a clone, replace the first line with `dir = "~/path/to/the/clone"`.

Options (defaults shown):

```lua
opts = {
  cmd = "rythe", -- the rythe CLI to run
}
```

Point it at another journal the same way the CLI does, with `RYTHE_DIR` or
`rythe config set storage.dir`.

## Keys

Everything is under the `<leader>j` which-key group "rythe".

| Key | Does | Status |
|---|---|---|
| `<leader>jj` | new entry; `:w` saves it | ✓ |
| `<leader>jf` | find an entry (picker with preview) | ✓ |
| `<leader>js` | search text | ✓ |
| `<leader>jt` | tags, then their entries | ✓ |
| `<leader>jr` | read the last week | ✓ |
| `<leader>jp` | new entry with a writing prompt | ✓ |
| `<leader>jR` | weekly review | ✓ |

## Buffers

An entry opens as `rythe://<id>` and a new one as `rythe://new`. They're ordinary buffers:
`:w` sends the text to `rythe edit <id> --stdin` (or `rythe new` for a new one, after which
the buffer is renamed to the new id), and `:e!` reloads from the CLI. You can also
`:e rythe://<id>` directly. Only the body is in the buffer, never the frontmatter. Writing an
empty buffer is refused by the CLI and the buffer stays modified. `<leader>jj` returns to an
unsaved `rythe://new` draft if there is one.

## Pickers

- `<leader>jf`: every entry, newest first: date, title (or first line), tags; the body is the
  preview.
- `<leader>js`: asks for text, then lists the entries that contain it with the first matching
  line (`+N` when more lines match). Opening one puts the cursor on the first match and sets the
  search register, so `n` and `N` move between matches.
- `<leader>jt`: tags with counts, most used first. Choosing one lists its entries.
- `<leader>jo`: entries written on today's date in earlier years.

## Reflect

- `<leader>jr`: the last seven days in one read-only markdown buffer, oldest first. `<CR>` on an
  entry opens it for editing (`<C-o>` comes back); `q` closes.
- `<leader>jp`: pick a prompt set (`today` first), then write a new entry with that set's prompt
  for today shown above the text. The prompt is virtual text: it is never saved, and it goes
  away once the entry is saved. The choice of prompt is the CLI's (`rythe prompts pick`), so
  it matches `rythe new --prompt`.
- `<leader>jR`: the weekly review. The period (past `#review` entries left out) is shown above,
  and a `rythe://review` buffer below with the title ("Week of …") and the reflection
  questions above the text. `:w` saves it through `rythe review --stdin`, titled and tagged
  `#review`, like `rythe review` does on the terminal.

## Tests

```sh
bin/test            # all specs
bin/test tests/cli_spec.lua
```

They run headless against a temp `RYTHE_DIR`, never the real journal.

## Licence

MIT. See [LICENSE](LICENSE).
