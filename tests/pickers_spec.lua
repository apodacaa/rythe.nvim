local helpers = require("tests.helpers")
local pickers = require("journal.pickers")

describe("entries picker", function()
  local notes

  before_each(function()
    notes = helpers.capture_notify()
    vim.cmd("silent! %bwipeout!")
    require("journal").setup({})
    helpers.temp_journal()
  end)

  it("builds items newest first with date, summary, tags and the body as preview", function()
    helpers.seed("2026-09-29T09:00:00", "\n  older one\nsecond line")
    helpers.seed("2026-09-30T16:46:08", "newer #work #idea")
    local items = pickers.entry_items(require("journal.cli").json({ "list" }))
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
      return vim.api.nvim_buf_get_name(0) == "journal://" .. id
    end)
    assert.are.equal("journal://" .. id, vim.api.nvim_buf_get_name(0))
    assert.are.same({ "pick me" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("says so when there are no entries", function()
    assert.is_nil(pickers.entries())
    assert.are.equal("no entries yet", notes[#notes].msg)
  end)
end)
