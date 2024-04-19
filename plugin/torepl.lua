if vim.g.loaded_torepl == 1 then
  return
end

vim.g.loaded_torepl = 1

vim.api.nvim_create_user_command(
  "ToReplBuffer",
  require("torepl").execute_buffer,
  {}
)
vim.api.nvim_create_user_command(
  "ToReplSelection",
  require("torepl").execute_selection,
  {}
)
