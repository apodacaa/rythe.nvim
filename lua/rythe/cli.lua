-- The only place that runs the rythe CLI.
local M = {}

-- Runs `rythe <args> --json`, optionally with text on stdin.
-- Returns the decoded JSON (JSON null becomes nil), or nil and an error
-- { code = exit code, message = stderr without the "rythe: " prefix }.
function M.json(args, opts)
  opts = opts or {}
  local cmd = { require("rythe").config.cmd }
  vim.list_extend(cmd, args)
  table.insert(cmd, "--json")

  -- Checked first so a missing CLI gets a plain sentence, not vim.system's ENOENT trace.
  if vim.fn.executable(cmd[1]) == 0 then
    return nil, { code = -1, message = "the rythe CLI isn't installed: no `" .. cmd[1] .. "` on your PATH" }
  end

  local ok, proc = pcall(vim.system, cmd, { text = true, stdin = opts.stdin })
  if not ok then
    return nil, { code = -1, message = "can't run " .. cmd[1] .. ": " .. tostring(proc) }
  end
  local res = proc:wait()
  if res.code ~= 0 then
    local msg = vim.trim(res.stderr or ""):gsub("^rythe: ", "")
    return nil, { code = res.code, message = msg }
  end

  local decoded, data = pcall(vim.json.decode, res.stdout, { luanil = { object = true, array = true } })
  if not decoded then
    return nil, { code = -1, message = "can't decode rythe output: " .. tostring(data) }
  end
  return data
end

function M.notify(err)
  vim.notify(err.message, vim.log.levels.ERROR, { title = "rythe" })
end

return M
