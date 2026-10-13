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

local function info(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "journal" })
end

-- A picker over entry objects, or a note when there are none.
local function pick_entries(entries, title, empty)
  if #entries == 0 then
    return info(empty)
  end
  return Snacks.picker.pick({
    title = title,
    items = M.entry_items(entries),
    format = format_entry,
    preview = "preview",
    confirm = open_entry,
  })
end

local function run(args)
  local data, err = cli.json(args)
  if not data then
    cli.notify(err)
  end
  return data
end

-- Every entry, newest first, with the body as preview.
function M.entries()
  local entries = run({ "list" })
  return entries and pick_entries(entries, "Journal", "no entries yet")
end

-- Entries with this tag.
function M.tagged(tag)
  local entries = run({ "list", "--tag", tag })
  return entries and pick_entries(entries, "Journal #" .. tag, "no entries tagged #" .. tag)
end

-- Entries written on today's date in earlier years.
function M.on_this_day()
  local entries = run({ "on-this-day" })
  return entries and pick_entries(entries, "On this day", "nothing on this day in other years")
end

-- `tags --json` is an object, so its order is lost in Lua: most used first, then by name.
function M.tag_items(counts)
  local items = {}
  for tag, count in pairs(counts) do
    items[#items + 1] = { text = "#" .. tag, tag = tag, count = count }
  end
  table.sort(items, function(a, b)
    if a.count ~= b.count then
      return a.count > b.count
    end
    return a.tag < b.tag
  end)
  for i, item in ipairs(items) do
    item.idx = i
  end
  return items
end

-- Every tag with its count; choosing one lists its entries.
function M.tags()
  local counts = run({ "tags" })
  if not counts then
    return
  end
  if vim.tbl_isempty(counts) then
    return info("no tags yet")
  end
  return Snacks.picker.pick({
    title = "Journal tags",
    items = M.tag_items(counts),
    format = function(item)
      return { { ("%4d  "):format(item.count), "SnacksPickerComment" }, { item.text, "SnacksPickerLabel" } }
    end,
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if item then
        M.tagged(item.tag)
      end
    end,
  })
end

function M.search_items(results)
  local items = {}
  for i, result in ipairs(results) do
    local entry = { created = result.created }
    local extra = #result.matches > 1 and ("+" .. (#result.matches - 1)) or ""
    items[i] = {
      idx = i,
      text = table.concat(result.matches, " "),
      id = result.id,
      when = when(entry),
      summary = vim.trim(result.matches[1] or ""),
      extra = extra,
      matches = result.matches,
    }
  end
  return items
end

-- search --json has no body, so the preview asks `journal show` once per entry.
local function preview_body(cache)
  return function(ctx)
    local item = ctx.item
    if not item.preview then
      cache[item.id] = cache[item.id] or cli.json({ "show", item.id })
      local entry = cache[item.id]
      item.preview = { text = entry and entry.body or "", ft = "markdown" }
    end
    return require("snacks.picker.preview").preview(ctx)
  end
end

-- Entries whose text matches `query` (asked for when not given). Opening one puts the cursor on
-- the first match and sets the search register, so `n` finds the next.
function M.search(query)
  if not query then
    return vim.ui.input({ prompt = "Search journal: " }, function(input)
      if input and vim.trim(input) ~= "" then
        M.search(vim.trim(input))
      end
    end)
  end
  local results = run({ "search", query })
  if not results then
    return
  end
  if #results == 0 then
    return info("nothing matches " .. query)
  end
  return Snacks.picker.pick({
    title = "Journal: " .. query,
    items = M.search_items(results),
    format = function(item)
      local ret = { { item.when, "SnacksPickerLabel" }, { "  " }, { item.summary } }
      if item.extra ~= "" then
        ret[#ret + 1] = { "  " .. item.extra, "SnacksPickerComment" }
      end
      return ret
    end,
    preview = preview_body({}),
    confirm = function(picker, item)
      picker:close()
      if item and require("journal.buffers").open(item.id) then
        vim.fn.setreg("/", "\\V\\c" .. vim.fn.escape(query, "\\"))
        vim.fn.search(vim.fn.getreg("/"), "cw")
      end
    end,
  })
end

return M
