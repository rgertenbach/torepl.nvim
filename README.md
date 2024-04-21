# ToRepl.nvim

ToRepl.nvim is a plugin that helps you run code in a REPL in Neovim.

It allows you to set filetype and filename specific mappings to commands.

## Installation

### Lazy

```lua
return {
    "rgertenbach/torepl.nvim",
    config = fuction()
      local torepl = require("torepl")
      torepl.setup({
        commands = {
          ["python"] = {
            -- This is in an array of configs.
            -- ToRepl will use the first matching command config.
            {
              pattern = "^.*_batch.py$",  -- Some made up example.
              cmd = "~/py/venv/bin/python -c \"%s\""
            },
            {
              cmd = "~/py/venv/bin/python -c \"%s\"",
              after = [[import IPython; IPython.embed()]],
            }
          },
          -- This is passing data instead of code into a pewritten program.
          ["csv"] = {
            cmd = [[~/py/venv/bin/python ~/.config/nvim/lua/rgertenbach/plugins/csv_loader.py %s]],
            pass_as = torepl.PassMethod.file
          },
        }
      })
      vim.keymap.set("n", "<leader>run", torepl.execute_buffer)
      vim.keymap.set("v", "<leader>run", torepl.execute_selection)
    end
}
```

