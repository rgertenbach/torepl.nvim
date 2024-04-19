-- TODO: support stdin or tempfile
--- stdin likely won't work because it sends an EOF as well.
--- bin "{code}"  # code is an arg
--- bin <(echo "${code}")  # file based with code in variable

local utils = require("torepl.utils")

---@class CmdConfig
---
---@field cmd string the command to execute.
---@field delimiter string? The delimiter separating the setup from the main code.
---@field pattern string? Which file pattern to apply this to.
---@field pass_as PassMethod? How the script is passed to `cmd`. Defaults to `"arg"`.

---@class ToReplConfig
---@field commands table<CmdConfig | CmdConfig[]>
--- A table mapping filetype to either:
--- - the command configuration
--- - a table mapping a filename pattern to a command confguration.
ToReplConfig = ToReplConfig or {}

local M = {}

---@enum PassMethod
---
--- How he script should be passed into the command.
M.PassMethod = {
  arg = "arg",   -- Passes the script as a single argument to the command.
  file = "file", -- Stores the script in a tempfile and passes the filepath. The `cmd` needs to handle deletion.
  -- stdin = "stdin",  -- Passes the script via stdin, beware how the `cmd` handles `EOF`.
}

---@param opt ToReplConfig The config, if empty this plugin is useless.
---@return nil
function M.setup(opt)
  opt = opt or {}
  ToReplConfig = vim.tbl_extend("force", ToReplConfig, opt)
end

---Extracts setup section from the current buffer.
---
---@param delim string The delimiter between the setup section and code.
---@param up_to integer? Up to which line (0-based) to scan the code.
--- Defaults to -1 (end of file)
---@return string[] # An array of lines.
--- Empty if no setup section is found.
function M.extract_setup(delim, up_to)
  if not delim then error("No delimiter for setup section defined.") end
  up_to = up_to or 1
  local lines = vim.api.nvim_buf_get_lines(0, 0, up_to, false)
  local delim_pos = -1
  for i, line in ipairs(lines) do
    if i > up_to then break end
    if line:find("^" .. delim) then
      delim_pos = i
      break
    end
  end
  if delim_pos == -1 then return {} end
  for i = delim_pos, #lines do lines[i] = nil end
  return lines
end

--- Gets the config for the current buffer or nil if none is set up.
---
---@return CmdConfig | nil # A CmdConfig if one matches, otherwise `nil`.
function M.get_buffer_config()
  local ft_config = ToReplConfig.commands[vim.bo.ft]
  if not ft_config then return end
  if ft_config.cmd then return ft_config end
  local filename = vim.api.nvim_buf_get_name(0)
  for _, config in pairs(ft_config) do
    if not config.pattern then return config end
    if filename:match(config.pattern) then return config end
  end
end

---Execute the current buffer into a REPL.
---
---@return nil
function M.execute_buffer()
  local ft_config = M.get_buffer_config()
  if not ft_config then return end
  local script = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  M.execute(script, ft_config)
end

---Executes the currently selected range.
---
--- If a setup delimiter is set up and the selection is after the delimiter
--- the setup will be executed as well.
---@return nil
function M.execute_selection()
  local ft_config = M.get_buffer_config()
  if not ft_config then return end
  local selection = M.get_selected_range()
  local script = {}
  if ft_config.delimiter then
    local setup = M.extract_setup(ft_config.delimiter, selection.first.row)
    utils.concat_in_place(script, setup)
  end
  if selection.mode == "V" then
    utils.concat_in_place(
      script,
      vim.api.nvim_buf_get_lines(0, selection.first.row, selection.last.row + 1, false))
  else
    utils.concat_in_place(
      script,
      vim.api.nvim_buf_get_text(
        0,
        selection.first.row, selection.first.col - 1,
        selection.last.row, selection.last.col,
        {}))
  end
  M.execute(script, ft_config)
end

---Executes the script according to the config.
---
---@param script string[] A table with one element per line of code.
---@param config CmdConfig The config that defines how to run the code.
---@return nil
function M.execute(script, config)
  vim.cmd.split()
  local pass_as = config.pass_as or M.PassMethod.arg
  local filename
  if pass_as == M.PassMethod.arg then
    vim.cmd.terminal(config.cmd:format(table.concat(script, "\n")))
  elseif pass_as == M.PassMethod.file then
    filename = os.tmpname()
    local file = assert(io.open(filename, "w"))
    file:write(table.concat(script, "\n"))
    file:close()
    vim.cmd.terminal(config.cmd:format(filename))
  else
    error("Unsupported pass method " .. pass_as)
  end
  vim.cmd.startinsert()
end

return M
