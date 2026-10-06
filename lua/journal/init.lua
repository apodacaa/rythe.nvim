local M = {}

M.config = {
  -- the journal CLI to run
  cmd = "journal",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({ { "<leader>j", group = "journal" } })
  end
end

return M
