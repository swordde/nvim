local M = {}

--- require("qwen").setup({ ... }) -- see lua/qwen/config.lua for all options
function M.setup(opts)
  local config = require("qwen.config")
  config.setup(opts)

  require("qwen.completion").setup()

  local km = config.options.keymaps

  if km.toggle_chat then
    vim.keymap.set("n", km.toggle_chat, function()
      require("qwen.chat").chat()
    end, { desc = "Qwen: toggle chat" })
  end

  local function visual_action(kind)
    return function()
      -- Ensure '< '> marks reflect the just-finished selection.
      vim.cmd("normal! \27")
      require("qwen.actions").run(kind)
    end
  end

  if km.explain then
    vim.keymap.set("v", km.explain, visual_action("explain"), { desc = "Qwen: explain selection" })
  end
  if km.fix then
    vim.keymap.set("v", km.fix, visual_action("fix"), { desc = "Qwen: fix selection" })
  end
  if km.refactor then
    vim.keymap.set("v", km.refactor, visual_action("refactor"), { desc = "Qwen: refactor selection" })
  end
  if km.tests then
    vim.keymap.set("v", km.tests, visual_action("tests"), { desc = "Qwen: generate tests for selection" })
  end
end

return M
