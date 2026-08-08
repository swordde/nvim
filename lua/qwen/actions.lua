-- Code actions run against the current visual selection: explain / fix /
-- refactor / generate tests. "explain" streams prose into a floating
-- window; the others produce code and open a diff for review.
local M = {}

local config = require("qwen.config")
local http = require("qwen.http")
local diff = require("qwen.diff")

local prompts = {
  explain = "Explain what this %s code does, clearly and concisely:\n\n```%s\n%s\n```",
  fix = "Find and fix any bugs in this %s code. Reply with ONLY the corrected code "
    .. "in a single fenced code block and no explanation:\n\n```%s\n%s\n```",
  refactor = "Refactor this %s code for clarity and quality without changing its "
    .. "behavior. Reply with ONLY the refactored code in a single fenced code block "
    .. "and no explanation:\n\n```%s\n%s\n```",
  tests = "Write unit tests for this %s code, using idioms appropriate for the "
    .. "language. Reply with ONLY the test code in a single fenced code block and "
    .. "no explanation:\n\n```%s\n%s\n```",
}

local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return "", start_line, end_line
  end

  if #lines == 1 then
    lines[1] = lines[1]:sub(start_col, end_col)
  else
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
  end

  return table.concat(lines, "\n"), start_line, end_line
end

local function extract_code_block(text)
  local code = text:match("```[%w_+-]*\n(.-)\n```")
  return code or vim.trim(text)
end

local function float_window(title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.7)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = title,
    title_pos = "center",
  })

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf })

  return buf, win
end

--- Run a named action ("explain" | "fix" | "refactor" | "tests") on the
--- current visual selection.
function M.run(kind)
  local template = prompts[kind]
  if not template then
    vim.notify("Qwen: unknown action " .. tostring(kind), vim.log.levels.ERROR)
    return
  end

  local selection, start_line, end_line = get_visual_selection()
  if selection == "" then
    vim.notify("Qwen: no selection", vim.log.levels.WARN)
    return
  end

  local opts = config.options
  local ft = vim.bo.filetype
  local lang = ft ~= "" and ft or "text"
  local prompt = string.format(template, lang, lang, selection)

  local messages = {
    { role = "system", content = opts.system_prompt },
    { role = "user", content = prompt },
  }

  if kind == "explain" then
    local buf, win = float_window(" Qwen: Explain ")
    local acc = {}
    http.stream_chat({
      url = opts.base_url .. opts.chat_endpoint,
      body = { model = opts.model, temperature = opts.temperature, messages = messages },
      on_delta = function(text)
        table.insert(acc, text)
        if vim.api.nvim_win_is_valid(win) then
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(acc), "\n", { plain = true }))
          vim.bo[buf].modifiable = false
        end
      end,
      on_error = function(err)
        vim.notify("Qwen error: " .. tostring(err), vim.log.levels.ERROR)
      end,
    })
    return
  end

  vim.notify("Qwen: thinking (" .. kind .. ")...", vim.log.levels.INFO)
  local acc = {}
  http.stream_chat({
    url = opts.base_url .. opts.chat_endpoint,
    body = { model = opts.model, temperature = opts.temperature, messages = messages },
    on_delta = function(text)
      table.insert(acc, text)
    end,
    on_done = function(full)
      local code = extract_code_block(full)
      if kind == "tests" then
        diff.show_new_file(code, ft)
      else
        diff.show(code, start_line, end_line)
      end
    end,
    on_error = function(err)
      vim.notify("Qwen error: " .. tostring(err), vim.log.levels.ERROR)
    end,
  })
end

return M
