local M = {}

function M.check()
  vim.health.start("qwen.nvim")

  if vim.fn.executable("curl") == 1 then
    vim.health.ok("curl found on PATH")
  else
    vim.health.error("curl not found on PATH - required for every request")
  end

  if vim.system then
    vim.health.ok("vim.system available (Neovim >= 0.10)")
  else
    vim.health.error("vim.system missing - qwen.nvim requires Neovim >= 0.10")
  end

  local config = require("qwen.config")
  local o = config.options
  vim.health.info("chat endpoint:   " .. o.base_url .. o.chat_endpoint)
  vim.health.info("infill endpoint: " .. o.base_url .. o.infill_endpoint)
  vim.health.info("ghost-text completion: " .. (o.completion.enabled and "enabled" or "disabled"))
  vim.health.warn(
    "Endpoints aren't pinged here (no network access from :checkhealth by design). "
      .. "Run :QwenChat to verify the server actually responds."
  )
end

return M
