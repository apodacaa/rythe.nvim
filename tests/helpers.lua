local M = {}

-- Points JOURNAL_DIR at a fresh temp folder. Errors if it would be anywhere else,
-- so a test can never touch the real journal.
function M.temp_journal()
  local dir = vim.fn.tempname() .. "-journal"
  vim.fn.mkdir(dir, "p")
  local tmp = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.tempname(), ":h:h"))
  assert(vim.startswith(vim.fs.normalize(dir), tmp), "refusing JOURNAL_DIR outside temp: " .. dir)
  vim.env.JOURNAL_DIR = dir
  return dir
end

-- Seeds an entry through the CLI and returns its id.
function M.seed(at, text)
  assert(vim.env.JOURNAL_DIR, "call temp_journal() first")
  local res = vim.system({ "journal", "new", "--at", at, "--text", text, "--json" }, { text = true }):wait()
  assert(res.code == 0, res.stderr)
  return vim.json.decode(res.stdout).id
end

return M
