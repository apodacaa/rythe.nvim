-- snacks pickers over CLI results.
local cli = require("journal.cli")

local M = {}

-- "2026-09-30T16:46:08+02:00" -> "2026-09-30 16:46"
local function when(entry)
  return entry.created:sub(1, 10) .. " " .. entry.created:sub(12, 16)
end

-- The title, or else the first non-blank line of the body.
local function summary(entry)
  if entry.title ~= "" then
    return entry.title
  end
  return entry.body:match("[^\n]*%S[^\n]*") or ""
end

function M.entry_items(entries)
  local items = {}
  for i, entry in ipairs(entries) do
    local tags = table.concat(
      vim.tbl_map(function(t)
        return "#" .. t
      end, entry.tags),
      " "
    )
    items[i] = {
      idx = i,
      text = table.concat({ when(entry), summary(entry), tags }, " "),
      entry = entry,
      when = when(entry),
      summary = vim.trim(summary(entry)),
      tags = tags,
      preview = { text = entry.body, ft = "markdown" },
    }
  end
  return items
end

local function format_entry(item)
  local ret = {
    { item.when, "SnacksPickerLabel" },
    { "  " },
    { item.summary },
  }
  if item.tags ~= "" then
    ret[#ret + 1] = { "  " }
    ret[#ret + 1] = { item.tags, "SnacksPickerComment" }
  end
  return ret
end

local function open_entry(picker, item)
  picker:close()
  if item then
    require("journal.buffers").open(item.entry.id)
  end
end

-- Every entry, newest first, with the body as preview.
function M.entries()
  local entries, err = cli.json({ "list" })
  if not entries then
    return cli.notify(err)
  end
  if #entries == 0 then
    return vim.notify("no entries yet", vim.log.levels.INFO, { title = "journal" })
  end
  return Snacks.picker.pick({
    title = "Journal",
    items = M.entry_items(entries),
    format = format_entry,
    preview = "preview",
    confirm = open_entry,
  })
end

return M
