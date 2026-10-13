-- The plugin's version and the changelog move together, so a release always has its notes.
describe("release", function()
  local version = require("journal").version

  it("has a version of three numbers", function()
    assert.is_truthy(version:match("^%d+%.%d+%.%d+$"))
  end)

  it("has the version as the newest changelog entry", function()
    local newest
    for line in io.lines("CHANGELOG.md") do
      newest = line:match("^## (%S+)")
      if newest then
        break
      end
    end
    assert.are.equal(version, newest)
  end)
end)
