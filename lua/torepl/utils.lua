---@class Position
---@field row integer 0 based row.
---@field col integer 0 based column.

---@class Selection
---@field first Position Where the selection starts.
---@field last Position Where the selection ends.
---@field mode string The type of selection.
--- If the mode is `"V"` only the rows of `first` and `last` matter.

local M = {}

--- Extends `t1` by adding `t2` at the end, in place.
---
---@param t1 table The table to append to.
---@param t2 table The table to append to `t1`.
---@return nil
function M.concat_in_place(t1, t2)
  for _, x in ipairs(t2) do table.insert(t1, x) end
end

--- Returns a table with the selected range in the buffer.
---
--- The earlier position in the text comes first, even if the selection is
--- backwards.
---
---@return Selection # The currently selected range.
function M.get_selected_range()
  local vpos = vim.fn.getpos("v")
  local first = { row = vpos[2] - 1, col = vpos[3] }
  local cpos = vim.api.nvim_win_get_cursor(0)
  local last = { row = cpos[1] - 1, col = cpos[2] + 1 }
  if last.row < first.row or (last.row == first.row and last.col < first.col) then
    first, last = last, first
  end
  return { first = first, last = last, mode = vim.fn.mode() }
end

return M
