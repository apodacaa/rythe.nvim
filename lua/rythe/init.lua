local M = {}

-- Bumped together with CHANGELOG.md; `bin/release` tags it.
M.version = "0.2.1"

M.config = {
  -- the rythe CLI to run
  cmd = "rythe",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local buffers = require("rythe.buffers")
  buffers.setup()

  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({ { "<leader>j", group = "rythe" } })
  end

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end
  map("<leader>jj", buffers.new, "New Entry")
  map("<leader>jf", function()
    require("rythe.pickers").entries()
  end, "Find Entry")
  map("<leader>js", function()
    require("rythe.pickers").search()
  end, "Search Entries")
  map("<leader>jt", function()
    require("rythe.pickers").tags()
  end, "Tags")
  map("<leader>jo", function()
    require("rythe.pickers").on_this_day()
  end, "On This Day")
  map("<leader>jr", function()
    require("rythe.read").week()
  end, "Read the Week")
  map("<leader>jp", function()
    require("rythe.pickers").prompt()
  end, "New Entry with a Prompt")
  map("<leader>jR", function()
    require("rythe.read").review()
  end, "Weekly Review")
end

return M
