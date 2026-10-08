-- journal://new and journal://<id> buffers. Reading and writing go through the CLI.
local cli = require("journal.cli")

local M = {}

local PREFIX = "journal://"

-- Entries already fetched by open(), handed to the BufReadCmd so it doesn't ask twice.
local fetched = {}

local function ref_of(buf)
  return vim.api.nvim_buf_get_name(buf):sub(#PREFIX + 1)
end

local function prepare(buf)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  -- The same as the journal_no_capcheck autocmd does for files: no "capital after a period"
  -- spell warnings and no completion popup while writing.
  vim.bo[buf].spellcapcheck = ""
  vim.b[buf].completion = false
end

local function set_text(buf, body)
  local lines = vim.split(body, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
end

local function read(ev)
  local buf, ref = ev.buf, ref_of(ev.buf)
  prepare(buf)
  if ref == "new" then
    set_text(buf, "")
    return
  end
  local entry, err = fetched[ref], nil
  fetched[ref] = nil
  if not entry then
    entry, err = cli.json({ "show", ref })
  end
  if not entry then
    return cli.notify(err)
  end
  set_text(buf, entry.body)
end

local function write(ev)
  local buf, ref = ev.buf, ref_of(ev.buf)
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
  local entry, err
  if ref == "new" then
    entry, err = cli.json({ "new" }, { stdin = text })
  else
    entry, err = cli.json({ "edit", ref, "--stdin" }, { stdin = text })
  end
  if not entry then
    return cli.notify(err)
  end
  if ref == "new" then
    -- Now it's that entry: the next :w edits it instead of making another one.
    local old = vim.api.nvim_buf_get_name(buf)
    vim.api.nvim_buf_set_name(buf, PREFIX .. entry.id)
    local alt = vim.fn.bufnr(old)
    if alt ~= -1 and alt ~= buf then
      vim.api.nvim_buf_delete(alt, { force = true })
    end
  end
  vim.bo[buf].modified = false
  vim.notify("saved " .. entry.id, vim.log.levels.INFO, { title = "journal" })
  if entry.resurfaced then
    M.show_resurfaced(entry.resurfaced)
  end
end

-- The older entry `journal new` picks after a save (as on the terminal): the first few lines
-- and how to open it.
function M.show_resurfaced(resurfaced)
  local old = resurfaced.entry
  local lines = {}
  if old.title ~= "" then
    lines[1] = old.title
  end
  for line in old.body:gmatch("[^\n]+") do
    if #lines == 3 then
      lines[#lines + 1] = "…"
      break
    end
    if line:match("%S") then
      lines[#lines + 1] = vim.trim(line)
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = ":e " .. PREFIX .. old.id
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, {
    title = "journal: " .. resurfaced.label,
    timeout = 10000,
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("journal_buffers", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", { group = group, pattern = PREFIX .. "*", callback = read })
  vim.api.nvim_create_autocmd("BufWriteCmd", { group = group, pattern = PREFIX .. "*", callback = write })
end

-- A blank entry. If one is already open, goes back to it (its text is kept).
function M.new()
  vim.cmd.edit(vim.fn.fnameescape(PREFIX .. "new"))
end

-- Opens an entry by any ref the CLI takes (id, `last`, `today`, a unique prefix).
-- Returns true if it did.
function M.open(ref)
  local entry, err = cli.json({ "show", ref })
  if not entry then
    cli.notify(err)
    return false
  end
  local name = PREFIX .. entry.id
  if vim.fn.bufloaded(name) == 0 then
    fetched[entry.id] = entry
  end
  vim.cmd.edit(vim.fn.fnameescape(name))
  return true
end

return M
