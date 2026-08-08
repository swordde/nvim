-- Copilot-style ghost-text completion, powered by llama.cpp server's
-- /infill endpoint (fill-in-the-middle). Works best with FIM-capable
-- code models (Qwen2.5-Coder, DeepSeek-Coder, CodeLlama, StarCoder2, ...).
local M = {}

local config = require("qwen.config")
local http = require("qwen.http")

local ns = vim.api.nvim_create_namespace("qwen_completion")

local state = {
  job = nil,
  timer = nil,
  suggestion = nil, -- { text, row, col }
  extmark_id = nil,
}

local function clear_suggestion()
  if state.extmark_id then
    pcall(vim.api.nvim_buf_del_extmark, 0, ns, state.extmark_id)
    state.extmark_id = nil
  end
  state.suggestion = nil
end

local function show_suggestion(text, row, col)
  clear_suggestion()
  if text == "" then
    return
  end

  local lines = vim.split(text, "\n", { plain = true })
  local virt_lines = {}
  for i = 2, #lines do
    table.insert(virt_lines, { { lines[i], "Comment" } })
  end

  local ok, id = pcall(vim.api.nvim_buf_set_extmark, 0, ns, row, col, {
    virt_text = { { lines[1], "Comment" } },
    virt_text_pos = "inline",
    virt_lines = virt_lines,
  })
  if ok then
    state.extmark_id = id
    state.suggestion = { text = text, row = row, col = col }
  end
end

local function gather_context(bufnr, row, col, ctx_lines)
  local last_line = vim.api.nvim_buf_line_count(bufnr)
  local start_line = math.max(0, row - ctx_lines)
  local end_line = math.min(last_line, row + ctx_lines)

  local before_lines = vim.api.nvim_buf_get_lines(bufnr, start_line, row, false)
  local cur_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  local after_lines = vim.api.nvim_buf_get_lines(bufnr, row + 1, end_line, false)

  local before_cursor = cur_line:sub(1, col)
  local after_cursor = cur_line:sub(col + 1)

  local prefix_parts = {}
  if #before_lines > 0 then
    table.insert(prefix_parts, table.concat(before_lines, "\n"))
  end
  table.insert(prefix_parts, before_cursor)
  local prefix = table.concat(prefix_parts, "\n")

  local suffix_parts = { after_cursor }
  if #after_lines > 0 then
    table.insert(suffix_parts, table.concat(after_lines, "\n"))
  end
  local suffix = table.concat(suffix_parts, "\n")

  return prefix, suffix
end

function M.trigger()
  local opts = config.options
  if not opts.completion.enabled then
    return
  end

  -- Skip scratch/floating buffers (chat input, diff views, etc.) - only
  -- suggest in real file buffers.
  if vim.bo.buftype ~= "" then
    return
  end

  if state.job then
    pcall(function()
      state.job:kill(9)
    end)
    state.job = nil
  end
  clear_suggestion()

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local prefix, suffix = gather_context(bufnr, row, col, opts.completion.context_lines)

  local body = {
    input_prefix = prefix,
    input_suffix = suffix,
    n_predict = opts.completion.n_predict,
    temperature = opts.temperature,
    stop = { "\n\n\n" },
  }

  state.job = http.post_json(opts.base_url .. opts.infill_endpoint, body, function(decoded, err)
    state.job = nil
    if err or not decoded then
      return
    end
    local text = decoded.content
    if not text or text == "" then
      return
    end

    -- Only render if the cursor is still where we asked from.
    if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
      return
    end
    local cur = vim.api.nvim_win_get_cursor(0)
    if cur[1] - 1 == row and cur[2] == col then
      show_suggestion(text, row, col)
    end
  end)
end

--- Accept the current suggestion. Returns true if one was applied.
function M.accept()
  if not state.suggestion then
    return false
  end
  local s = state.suggestion
  local lines = vim.split(s.text, "\n", { plain = true })
  vim.api.nvim_buf_set_text(0, s.row, s.col, s.row, s.col, lines)

  local last_line = s.row + #lines - 1
  local last_col = (#lines == 1) and (s.col + #lines[1]) or #lines[#lines]
  vim.api.nvim_win_set_cursor(0, { last_line + 1, last_col })

  clear_suggestion()
  return true
end

function M.dismiss()
  if state.job then
    pcall(function()
      state.job:kill(9)
    end)
    state.job = nil
  end
  clear_suggestion()
end

function M.toggle()
  local opts = config.options
  opts.completion.enabled = not opts.completion.enabled
  if not opts.completion.enabled then
    M.dismiss()
  end
  vim.notify("Qwen completion: " .. (opts.completion.enabled and "on" or "off"))
end

function M.setup()
  local opts = config.options
  local grp = vim.api.nvim_create_augroup("QwenCompletion", { clear = true })

  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = grp,
    callback = function()
      M.dismiss()
    end,
  })

  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = grp,
    callback = function()
      clear_suggestion()
      if state.timer then
        pcall(function()
          state.timer:stop()
        end)
      end
      state.timer = vim.defer_fn(function()
        M.trigger()
      end, opts.completion.debounce_ms)
    end,
  })

  vim.keymap.set("i", opts.completion.keymap_accept, function()
    if M.accept() then
      return ""
    end
    return vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
  end, { expr = true, desc = "Qwen: accept suggestion" })

  vim.keymap.set("i", opts.completion.keymap_dismiss, function()
    M.dismiss()
  end, { desc = "Qwen: dismiss suggestion" })
end

return M
