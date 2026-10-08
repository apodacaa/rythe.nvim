local helpers = require("tests.helpers")
local cli = require("journal.cli")
local read = require("journal.read")
local buffers = require("journal.buffers")

local function days_ago(n, hm)
  return os.date("%Y-%m-%dT" .. (hm or "09:00") .. ":00", os.time() - n * 86400)
end

local function lines(buf)
  return vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false)
end

local function has(list, pattern)
  for _, l in ipairs(list) do
    if l:find(pattern) then
      return true
    end
  end
  return false
end

describe("read", function()
  local notes

  before_each(function()
    notes = helpers.capture_notify()
    vim.cmd("silent! only | silent! %bwipeout!")
    require("journal").setup({})
    helpers.temp_journal()
  end)

  it("shows a stretch of entries oldest first as headings and bodies", function()
    helpers.seed("2026-10-01T09:05:00", "first\n\n")
    local id = helpers.seed("2026-10-02T21:30:00", "second\nmore")
    local entries = vim.fn.reverse(cli.json({ "list" }))
    local buf = read.show(entries, "Some days")
    assert.are.same({
      "# Some days",
      "",
      "## Thu Oct 1, 2026 · 09:05",
      "",
      "first",
      "",
      "## Fri Oct 2, 2026 · 21:30",
      "",
      "second",
      "more",
      "",
    }, lines(buf))
    assert.is_false(vim.bo[buf].modifiable)
    assert.are.equal("markdown", vim.bo[buf].filetype)
    assert.is_nil(read.entry_at(buf, 2))
    assert.are.equal(id, read.entry_at(buf, 10))
  end)

  it("<CR> opens the entry under the cursor", function()
    helpers.seed(days_ago(1), "yesterday")
    local id = helpers.seed(days_ago(0, "00:01"), "today")
    read.week()
    vim.fn.search("^today$")
    vim.cmd("normal \r")
    assert.are.equal("journal://" .. id, vim.api.nvim_buf_get_name(0))
  end)

  it("week: the last seven days only", function()
    helpers.seed(days_ago(10), "too old")
    helpers.seed(days_ago(6), "six days ago")
    helpers.seed(days_ago(0, "00:01"), "today")
    read.week()
    local text = lines()
    assert.are.equal("# The last 7 days", text[1])
    assert.is_true(has(text, "^six days ago$"))
    assert.is_true(has(text, "^today$"))
    assert.is_false(has(text, "too old"))
  end)

  it("says so when nothing was written", function()
    read.week()
    assert.are.equal("_Nothing written in this period._", lines()[3])
  end)
end)

describe("weekly review", function()
  local notes

  before_each(function()
    notes = helpers.capture_notify()
    vim.cmd("silent! only | silent! %bwipeout!")
    require("journal").setup({})
    helpers.temp_journal()
  end)

  it("shows the period above and a reflection buffer with title and question below", function()
    helpers.seed(days_ago(2), "a day this week")
    helpers.seed(days_ago(1), "last review #review")
    read.review()
    local plan = cli.json({ "review" })

    assert.are.equal(2, #vim.api.nvim_tabpage_list_wins(0))
    assert.are.equal("journal://review", vim.api.nvim_buf_get_name(0))
    local guide = buffers.guide()
    assert.are.equal(plan.title, guide[1])
    assert.are.equal("", guide[#guide])
    local squash = function(t)
      return vim.trim(t:gsub("%s+", " "))
    end
    assert.are.equal(squash(plan.prompt), squash(table.concat(guide, " ", 2)))
    assert.is_true(has(guide, "^%- Where did your energy go")) -- the question's list stays a list

    local above = vim.api.nvim_win_get_buf(vim.fn.win_getid(vim.fn.winnr("k")))
    local text = lines(above)
    assert.are.equal("# " .. plan.title, text[1])
    assert.is_true(has(text, "^a day this week$"))
    assert.is_false(has(text, "last review"))
  end)

  it(":w saves a titled #review entry without the guide", function()
    read.review()
    local plan = cli.json({ "review" })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "good week" })
    vim.cmd.write()
    local entry = cli.json({ "show", "last" })
    assert.are.equal(plan.title, entry.title)
    assert.are.same({ "review" }, entry.tags)
    assert.is_nil(entry.body:find(plan.prompt, 1, true))
    assert.are.equal("journal://" .. entry.id, vim.api.nvim_buf_get_name(0))
    assert.are.same({}, buffers.guide())
  end)
end)
