local M = {}

-- Defaults are tuned for a llama.cpp `server` instance running locally,
-- with an OpenAI-compatible /v1/chat/completions endpoint and the native
-- /infill endpoint (used for ghost-text completion on FIM-capable models
-- such as Qwen2.5-Coder, DeepSeek-Coder, CodeLlama, StarCoder2).
M.defaults = {
  base_url = "http://127.0.0.1:8081",
  chat_endpoint = "/v1/chat/completions",
  infill_endpoint = "/infill",

  -- Sent as the "model" field. llama.cpp server ignores this if it only
  -- serves one model, but harmless to set.
  model = "qwen",

  temperature = 0.2,
  system_prompt = "You are a concise, expert local coding assistant running inside Neovim.",

  completion = {
    enabled = true,
    debounce_ms = 400,
    -- how many lines of surrounding context to send for infill
    context_lines = 100,
    n_predict = 128,
    keymap_accept = "<Tab>",
    keymap_dismiss = "<C-]>",
  },

  chat = {
    width_ratio = 0.8,
    height_ratio = 0.8,
    input_height = 4,
  },

  keymaps = {
    toggle_chat = "<leader>aa",
    explain = "<leader>ae",
    fix = "<leader>af",
    refactor = "<leader>ar",
    tests = "<leader>at",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
  return M.options
end

return M
