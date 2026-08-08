if vim.g.loaded_qwen then
  return
end
vim.g.loaded_qwen = true

vim.api.nvim_create_user_command("QwenChat", function()
  require("qwen.chat").chat()
end, { desc = "Open the Qwen chat window" })

vim.api.nvim_create_user_command("QwenClear", function()
  require("qwen.chat").clear()
end, { desc = "Clear Qwen chat history" })

vim.api.nvim_create_user_command("QwenExplain", function()
  require("qwen.actions").run("explain")
end, { range = true, desc = "Explain the current visual selection" })

vim.api.nvim_create_user_command("QwenFix", function()
  require("qwen.actions").run("fix")
end, { range = true, desc = "Fix bugs in the current visual selection" })

vim.api.nvim_create_user_command("QwenRefactor", function()
  require("qwen.actions").run("refactor")
end, { range = true, desc = "Refactor the current visual selection" })

vim.api.nvim_create_user_command("QwenTests", function()
  require("qwen.actions").run("tests")
end, { range = true, desc = "Generate tests for the current visual selection" })

vim.api.nvim_create_user_command("QwenCompletionToggle", function()
  require("qwen.completion").toggle()
end, { desc = "Toggle ghost-text inline completion" })
