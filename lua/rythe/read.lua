-- A read-only markdown buffer showing a stretch of entries, oldest first.
local cli = require("rythe.cli")

local M = {}

local PREFIX = "rythe-read://"

-- "## Thu Oct 2, 2026 · 09:00 · Title"
local function heading(entry)
  local y, mo, d, h, mi = entry.created:match("^(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
  local t = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = 12 })
  local text = ("## %s %d, %s · %s:%s"):format(os.date("%a %b", t), tonumber(d), y, h, mi)
  if entry.title ~= "" then
    text = text .. " · " .. entry.title
  end
  return text
end

-- Renders `entries` (oldest first) under `title` in the current window. Each entry is a heading
-- and its body. <CR> opens the entry under the cursor for editing; q closes.
function M.show(entries, title)
  local lines, starts = { "# " .. title, "" }, {}
  for _, entry in ipairs(entries) do
    starts[#starts + 1] = { line = #lines + 1, id = entry.id }
    lines[#lines + 1] = heading(entry)
    lines[#lines + 1] = ""
    local body = vim.split(entry.body, "\n", { plain = true })
    while #body > 0 and vim.trim(body[#body]) == "" do
      table.remove(body)
    end
    vim.list_extend(lines, body)
    lines[#lines + 1] = ""
  end
  if #entries == 0 then
    lines[#lines + 1] = "_Nothing written in this period._"
  end

  local name = PREFIX .. title
  local old = vim.fn.bufnr(name)
  if old ~= -1 then
    vim.api.nvim_buf_delete(old, { force = true })
  end
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "hide" -- so <C-o> after <CR> comes back to it
  vim.bo[buf].filetype = "markdown"
  vim.b[buf].rythe_starts = starts

  vim.keymap.set("n", "<CR>", function()
    local id = M.entry_at(buf, vim.fn.line("."))
    if id then
      require("rythe.buffers").open(id)
    end
  end, { buffer = buf, desc = "Open Entry" })
  vim.keymap.set("n", "q", "<cmd>bdelete<cr>", { buffer = buf, desc = "Close" })

  vim.api.nvim_win_set_buf(0, buf)
  return buf
end

-- The id of the entry whose text is at `lnum`, or nil above the first entry.
function M.entry_at(buf, lnum)
  local id
  for _, start in ipairs(vim.b[buf].rythe_starts or {}) do
    if start.line > lnum then
      break
    end
    id = start.id
  end
  return id
end

-- The last seven days, today included.
function M.week()
  local since = os.date("%Y-%m-%d", os.time() - 6 * 86400)
  local entries, err = cli.json({ "list", "--since", since })
  if not entries then
    return cli.notify(err)
  end
  return M.show(vim.fn.reverse(entries), "The last 7 days")
end

-- The weekly review: the period above, the reflection below (`rythe review --json`).
function M.review()
  local plan, err = cli.json({ "review" })
  if not plan then
    return cli.notify(err)
  end
  M.show(plan.entries, plan.title)
  vim.cmd("belowright split")
  require("rythe.buffers").review(plan)
end

return M
