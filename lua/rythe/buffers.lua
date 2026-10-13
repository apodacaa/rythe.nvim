-- rythe://new, rythe://review and rythe://<id> buffers. Reading and writing go through
-- the CLI.
local cli = require("rythe.cli")

local M = {}

local PREFIX = "rythe://"

-- Buffers that create an entry on :w, and the command that does it (text on stdin).
local CREATE = {
  new = { "new" },
  review = { "review", "--stdin" },
}

-- Prompts and titles shown above the text as virtual lines: never part of the buffer, never saved.
local guide_ns = vim.api.nvim_create_namespace("rythe_guide")

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
  if CREATE[ref] then
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
  local entry, err = cli.json(CREATE[ref] or { "edit", ref, "--stdin" }, { stdin = text })
  if not entry then
    return cli.notify(err)
  end
  if CREATE[ref] then
    -- The CLI drops the prompt on save, so the guide goes too.
    vim.api.nvim_buf_clear_namespace(buf, guide_ns, 0, -1)
    -- Now it's that entry: the next :w edits it instead of making another one.
    local old = vim.api.nvim_buf_get_name(buf)
    vim.api.nvim_buf_set_name(buf, PREFIX .. entry.id)
    local alt = vim.fn.bufnr(old)
    if alt ~= -1 and alt ~= buf then
      vim.api.nvim_buf_delete(alt, { force = true })
    end
  end
  vim.bo[buf].modified = false
  vim.notify("saved " .. entry.id, vim.log.levels.INFO, { title = "rythe" })
  if entry.resurfaced then
    M.show_resurfaced(entry.resurfaced)
  end
end

-- The older entry `rythe new` picks after a save (as on the terminal): the first few lines
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
    title = "rythe: " .. resurfaced.label,
    timeout = 10000,
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("rythe_buffers", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", { group = group, pattern = PREFIX .. "*", callback = read })
  vim.api.nvim_create_autocmd("BufWriteCmd", { group = group, pattern = PREFIX .. "*", callback = write })
end

-- Wraps each line of `text` to `width`, keeping its line breaks (prompts can be lists).
local function wrap(text, width)
  local out = {}
  for _, para in ipairs(vim.split(vim.trim(text), "\n", { plain = true })) do
    local line = ""
    for word in para:gmatch("%S+") do
      if line ~= "" and #line + 1 + #word > width then
        out[#out + 1] = line
        line = word
      else
        line = line == "" and word or (line .. " " .. word)
      end
    end
    out[#out + 1] = line
  end
  return out
end

-- Shows `title` (optional) and `prompt` above the current buffer's text as virtual lines.
local function set_guide(title, prompt)
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, guide_ns, 0, -1)
  local width = math.min(vim.api.nvim_win_get_width(0) - 4, 76)
  local virt = {}
  if title then
    virt[#virt + 1] = { { title, "Title" } }
  end
  for _, line in ipairs(wrap(prompt, width)) do
    virt[#virt + 1] = { { line, "Comment" } }
  end
  virt[#virt + 1] = { { "" } }
  vim.api.nvim_buf_set_extmark(buf, guide_ns, 0, 0, { virt_lines = virt, virt_lines_above = true })
  -- Lines above line 1 only show when the window is scrolled to reveal them.
  vim.fn.winrestview({ topline = 1, topfill = #virt })
end

-- The guide shown in the current buffer, as text lines.
function M.guide(buf)
  local lines = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf or 0, guide_ns, 0, -1, { details = true })) do
    for _, chunks in ipairs(mark[4].virt_lines or {}) do
      lines[#lines + 1] = table.concat(vim.tbl_map(function(c)
        return c[1]
      end, chunks))
    end
  end
  return lines
end

-- A blank entry. If one is already open, goes back to it (its text is kept). With `prompt`, the
-- prompt is shown above the text and not saved.
function M.new(prompt)
  vim.cmd.edit(vim.fn.fnameescape(PREFIX .. "new"))
  if prompt then
    set_guide(nil, prompt)
  end
end

-- The reflection for `plan` (from `rythe review --json`): its title and question shown above
-- the text; :w saves it through `rythe review --stdin` (titled, tagged #review).
function M.review(plan)
  vim.cmd.edit(vim.fn.fnameescape(PREFIX .. "review"))
  set_guide(plan.title, plan.prompt)
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
