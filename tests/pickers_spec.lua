local helpers = require("tests.helpers")
local pickers = require("rythe.pickers")

describe("entries picker", function()
  local notes

  before_each(function()
    notes = helpers.capture_notify()
    vim.cmd("silent! %bwipeout!")
    require("rythe").setup({})
    helpers.temp_journal()
  end)

  it("builds items newest first with date, summary, tags and the body as preview", function()
    helpers.seed("2026-09-29T09:00:00", "\n  older one\nsecond line")
    helpers.seed("2026-09-30T16:46:08", "newer #work #idea")
    local items = pickers.entry_items(require("rythe.cli").json({ "list" }))
    assert.are.equal(2, #items)
    assert.are.equal("2026-09-30 16:46", items[1].when)
    assert.are.equal("#work #idea", items[1].tags)
    assert.are.equal("older one", items[2].summary)
    assert.are.same({ text = "\n  older one\nsecond line\n", ft = "markdown" }, items[2].preview)
  end)

  it("opens the chosen entry in a journal buffer", function()
    local id = helpers.seed("2026-09-30T16:46:08", "pick me")
    local picker = pickers.entries()
    vim.wait(2000, function()
      return picker:count() == 1
    end)
    picker:action("confirm")
    vim.wait(2000, function()
      return vim.api.nvim_buf_get_name(0) == "rythe://" .. id
    end)
    assert.are.equal("rythe://" .. id, vim.api.nvim_buf_get_name(0))
    assert.are.same({ "pick me" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("says so when there are no entries", function()
    assert.is_nil(pickers.entries())
    assert.are.equal("no entries yet", notes[#notes].msg)
  end)
end)

-- Waits for the picker to have `n` items, then confirms the first.
local function confirm(picker, n)
  vim.wait(2000, function()
    return picker:count() == n
  end)
  assert.are.equal(n, picker:count())
  picker:action("confirm")
end

local function wait_for_buf(name)
  vim.wait(2000, function()
    return vim.api.nvim_buf_get_name(0) == name
  end)
  assert.are.equal(name, vim.api.nvim_buf_get_name(0))
end

describe("search picker", function()
  local notes

  before_each(function()
    notes = helpers.capture_notify()
    vim.cmd("silent! %bwipeout!")
    require("rythe").setup({})
    helpers.temp_journal()
  end)

  it("lists matching entries with the first matching line and how many more", function()
    helpers.seed("2026-09-29T09:00:00", "no match here")
    helpers.seed("2026-09-30T16:46:08", "intro\nCoffee with Sam\nmore coffee later")
    local items = pickers.search_items(require("rythe.cli").json({ "search", "coffee" }))
    assert.are.equal(1, #items)
    assert.are.equal("Coffee with Sam", items[1].summary)
    assert.are.equal("+1", items[1].extra)
    assert.are.equal("2026-09-30 16:46", items[1].when)
  end)

  it("opens the entry on the first match with the search register set", function()
    local id = helpers.seed("2026-09-30T16:46:08", "intro\nfirst line\nCoffee with Sam")
    confirm(pickers.search("coffee"), 1)
    wait_for_buf("rythe://" .. id)
    assert.are.equal(3, vim.fn.line("."))
    assert.are.equal(1, vim.fn.search(vim.fn.getreg("/"), "n") > 0 and 1 or 0)
    assert.are.equal("\\V\\ccoffee", vim.fn.getreg("/"))
  end)

  it("previews the body through rythe show", function()
    helpers.seed("2026-09-30T16:46:08", "intro\nCoffee with Sam")
    local picker = pickers.search("coffee")
    vim.wait(2000, function()
      return picker:count() == 1 and picker.preview.win.buf ~= nil
        and vim.api.nvim_buf_get_lines(picker.preview.win.buf, 0, -1, false)[2] == "Coffee with Sam"
    end)
    assert.are.same({ "intro", "Coffee with Sam" }, vim.api.nvim_buf_get_lines(picker.preview.win.buf, 0, 2, false))
    picker:close()
  end)

  it("says so when nothing matches", function()
    helpers.seed("2026-09-30T16:46:08", "hello")
    assert.is_nil(pickers.search("zebra"))
    assert.are.equal("nothing matches zebra", notes[#notes].msg)
  end)
end)

describe("tags picker", function()
  local notes

  before_each(function()
    notes = helpers.capture_notify()
    vim.cmd("silent! %bwipeout!")
    require("rythe").setup({})
    helpers.temp_journal()
  end)

  it("orders tags by count, then name", function()
    local items = pickers.tag_items({ b = 1, a = 1, top = 5 })
    assert.are.same({ "top", "a", "b" }, vim.tbl_map(function(i)
      return i.tag
    end, items))
  end)

  it("choosing a tag lists only its entries, and choosing one opens it", function()
    helpers.seed("2026-09-29T09:00:00", "other #work")
    local id = helpers.seed("2026-09-30T16:46:08", "tagged #idea")
    confirm(pickers.tags(), 2) -- equal counts sort by name, so #idea is first
    local entries
    vim.wait(2000, function()
      entries = Snacks.picker.get({ source = nil })
      return #entries > 0 and entries[1].opts.title == "rythe #idea"
    end)
    assert.are.equal("rythe #idea", entries[1].opts.title)
    confirm(entries[1], 1)
    wait_for_buf("rythe://" .. id)
  end)

  it("says so when there are no tags", function()
    helpers.seed("2026-09-30T16:46:08", "untagged")
    assert.is_nil(pickers.tags())
    assert.are.equal("no tags yet", notes[#notes].msg)
  end)
end)

describe("prompt picker", function()
  before_each(function()
    helpers.capture_notify()
    vim.cmd("silent! %bwipeout!")
    require("rythe").setup({})
    helpers.temp_journal()
  end)

  it("lists prompt sets and opens a new entry with that set's prompt for today", function()
    local sets = require("rythe.cli").json({ "prompts", "list" })
    confirm(pickers.prompt(), #sets) -- the first row is `today`, the CLI's default
    wait_for_buf("rythe://new")
    local picked = require("rythe.cli").json({ "prompts", "pick", "today" })
    local guide = require("rythe.buffers").guide()
    local squash = function(t)
      return vim.trim(t:gsub("%s+", " "))
    end
    assert.are.equal(squash(picked.prompt), squash(table.concat(guide, " ")))
  end)
end)
