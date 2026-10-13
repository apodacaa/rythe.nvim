# Changelog

What changed in each version, newest first. The version is `require("rythe").version`. Versions
follow [semantic versioning](https://semver.org): from 1.0.0 on, a change that breaks a keymap or
a `setup()` option is a new major version.

## 0.2.0

**Renamed from journal.nvim to rythe.nvim**, following the CLI, which is now `rythe` (a rythe is a
small stream; say "rye-th"). Needs `rythe` 0.2.0 or later.

- The Lua module is `rythe`: `require("rythe").setup()`.
- The plugin runs the `rythe` command by default.
- Buffers are `rythe://new`, `rythe://<id>`, `rythe://review` and `rythe-read://…`.
- The repository is `apodacaa/rythe.nvim`.

The keys under `<leader>j` and the `setup()` options are unchanged.

## 0.1.1

Released as journal.nvim, like 0.1.0; the names below are as they were then.


- A missing `journal` CLI is reported as "the journal CLI isn't installed", not as a system error.
- The README has requirements and an install from GitHub.

## 0.1.0

The first tagged version. Needs `journal` 0.1.0 or later.

- A `<leader>j` menu: new entry, find, search, tags and on this day.
- Entries open in `journal://` buffers that save through the CLI.
- Read the week, write from a prompt, and a weekly review.
