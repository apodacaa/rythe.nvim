local M = {}

-- Bumped together with CHANGELOG.md; `bin/release` tags it.
M.version = "0.1.1"

M.config = {
  -- the journal CLI to run
  cmd = "journal",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local buffers = require("journal.buffers")
  buffers.setup()

  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({ { "<leader>j", group = "journal" } })
  end

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end
  map("<leader>jj", buffers.new, "New Entry")
  map("<leader>jf", function()
    require("journal.pickers").entries()
  end, "Find Entry")
  map("<leader>js", function()
    require("journal.pickers").search()
  end, "Search Entries")
  map("<leader>jt", function()
    require("journal.pickers").tags()
  end, "Tags")
  map("<leader>jo", function()
    require("journal.pickers").on_this_day()
  end, "On This Day")
  map("<leader>jr", function()
    require("journal.read").week()
  end, "Read the Week")
  map("<leader>jp", function()
    require("journal.pickers").prompt()
  end, "New Entry with a Prompt")
  map("<leader>jR", function()
    require("journal.read").review()
  end, "Weekly Review")
end

return M
