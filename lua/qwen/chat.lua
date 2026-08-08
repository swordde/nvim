-- Floating chat window: a read-only transcript pane on top and a
-- multi-line input box below. <CR> inserts a newline like a normal buffer;
-- <C-s> sends. Responses stream in token by token.
local M = {}

local config = require("qwen.config")
local http = require("qwen.http")

local history = {}
local transcript_buf, transcript_win
local input_buf, input_win
local current_job = nil

local function is_open()
  return transcript_win and vim.api.nvim_win_is_valid(transcript_win)
end

local function scroll_to_end()
  if is_open() then
    local n = vim.api.nvim_buf_line_count(transcript_buf)
    pcall(vim.api.nvim_win_set_cursor, transcript_win, { n, 0 })
  end
end

local function append_transcript(lines)
  vim.bo[transcript_buf].modifiable = true
  local existing = vim.api.nvim_buf_line_count(transcript_buf)
  if existing == 1 and vim.api.nvim_buf_get_lines(transcript_buf, 0, 1, false)[1] == "" then
    vim.api.nvim_buf_set_lines(transcript_buf, 0, 1, false, lines)
  else
    vim.api.nvim_buf_set_lines(transcript_buf, -1, -1, false, lines)
  end
  vim.bo[transcript_buf].modifiable = false
  scroll_to_end()
end

local function replace_from(from_line, lines)
  vim.bo[transcript_buf].modifiable = true
  vim.api.nvim_buf_set_lines(transcript_buf, from_line, -1, false, lines)
  vim.bo[transcript_buf].modifiable = false
  scroll_to_end()
end

local function close_chat()
  if current_job then
    pcall(function()
      current_job:kill(9)
    end)
    current_job = nil
  end
  for _, w in ipairs({ input_win, transcript_win }) do
    if w and vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_win_close(w, true)
    end
  end
  transcript_win, input_win = nil, nil
end

local function cancel_request()
  if current_job then
    pcall(function()
      current_job:kill(9)
    end)
    current_job = nil
    vim.notify("Qwen: request cancelled", vim.log.levels.WARN)
  end
end

function M.clear()
  history = {}
  if transcript_buf and vim.api.nvim_buf_is_valid(transcript_buf) then
    vim.bo[transcript_buf].modifiable = true
    vim.api.nvim_buf_set_lines(transcript_buf, 0, -1, false, { "" })
    vim.bo[transcript_buf].modifiable = false
  end
end

local function open_chat()
  if is_open() then
    vim.api.nvim_set_current_win(input_win)
    vim.cmd("startinsert")
    return
  end

  local c = config.options.chat
  local width = math.floor(vim.o.columns * c.width_ratio)
  local total_height = math.floor(vim.o.lines * c.height_ratio)
  local input_height = c.input_height
  local transcript_height = total_height - input_height - 1

  local row = math.floor((vim.o.lines - total_height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  transcript_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[transcript_buf].bufhidden = "wipe"
  vim.bo[transcript_buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(transcript_buf, 0, -1, false, { "" })
  vim.bo[transcript_buf].modifiable = false

  transcript_win = vim.api.nvim_open_win(transcript_buf, false, {
    relative = "editor",
    width = width,
    height = transcript_height,
    row = row,
    col = col,
    border = "rounded",
    title = " Qwen Chat ",
    title_pos = "center",
  })
  vim.wo[transcript_win].wrap = true
  vim.wo[transcript_win].linebreak = true

  input_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[input_buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })

  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = width,
    height = input_height,
    row = row + transcript_height + 1,
    col = col,
    border = "rounded",
    title = " Enter=newline  C-s=send  C-c=cancel  C-l=clear  q=quit ",
    title_pos = "center",
  })
  vim.wo[input_win].wrap = true

  vim.cmd("startinsert")

  local function map(modes, lhs, rhs, buf)
    vim.keymap.set(modes, lhs, rhs, { buffer = buf, silent = true })
  end

  map({ "n", "i" }, "<C-s>", function()
    M.send()
  end, input_buf)
  map({ "n", "i" }, "<C-c>", cancel_request, input_buf)
  map({ "n", "i" }, "<C-l>", function()
    M.clear()
  end, input_buf)
  map("n", "q", close_chat, input_buf)
  map("n", "q", close_chat, transcript_buf)
end

function M.send()
  if current_job then
    vim.notify("Qwen: still waiting on a response (C-c to cancel)", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  local prompt = vim.trim(table.concat(lines, "\n"))
  if prompt == "" then
    return
  end

  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })
  table.insert(history, { role = "user", content = prompt })

  local block = { "### You", "" }
  vim.list_extend(block, vim.split(prompt, "\n", { plain = true }))
  vim.list_extend(block, { "", "### Assistant", "" })
  append_transcript(block)

  local answer_start = vim.api.nvim_buf_line_count(transcript_buf) - 1
  local acc = {}

  local opts = config.options
  local messages = {}
  if opts.system_prompt and opts.system_prompt ~= "" then
    table.insert(messages, { role = "system", content = opts.system_prompt })
  end
  vim.list_extend(messages, history)

  current_job = http.stream_chat({
    url = opts.base_url .. opts.chat_endpoint,
    body = { model = opts.model, temperature = opts.temperature, messages = messages },
    on_delta = function(text)
      table.insert(acc, text)
      replace_from(answer_start, vim.split(table.concat(acc), "\n", { plain = true }))
    end,
    on_done = function(full)
      current_job = nil
      table.insert(history, { role = "assistant", content = full })
      replace_from(answer_start, vim.split(full, "\n", { plain = true }))
      append_transcript({ "" })
    end,
    on_error = function(err)
      current_job = nil
      replace_from(answer_start, { "_[error: " .. tostring(err) .. "]_" })
    end,
  })
end

function M.chat()
  open_chat()
end

return M
