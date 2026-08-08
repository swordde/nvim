-- Side-by-side diff review for AI suggestions, with accept/reject.
local M = {}

local state = {}

local function make_scratch_buf(lines, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  if ft and ft ~= "" then
    vim.bo[buf].filetype = ft
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end

local function bind(buf, accept, reject)
  vim.keymap.set("n", "a", accept, { buffer = buf, desc = "Qwen: accept suggestion" })
  vim.keymap.set("n", "q", reject, { buffer = buf, desc = "Qwen: reject suggestion" })
  vim.keymap.set("n", "r", reject, { buffer = buf, desc = "Qwen: reject suggestion" })
end

--- Show a diff between `original_lines`/`start_line`..`end_line` in the ORIGINAL
--- buffer (1-indexed, inclusive) and `new_code` (string). On accept, replaces
--- those lines in that buffer.
function M.show(new_code, start_line, end_line)
  local target_buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[target_buf].filetype
  local original_lines = vim.api.nvim_buf_get_lines(target_buf, start_line - 1, end_line, false)
  local new_lines = vim.split(new_code, "\n", { plain = true })

  vim.cmd("tabnew")
  local left_buf = make_scratch_buf(original_lines, ft)
  vim.api.nvim_win_set_buf(0, left_buf)
  vim.cmd("diffthis")

  vim.cmd("vsplit")
  local right_buf = make_scratch_buf(new_lines, ft)
  vim.api.nvim_win_set_buf(0, right_buf)
  vim.cmd("diffthis")

  state = {
    target_buf = target_buf,
    start_line = start_line,
    end_line = end_line,
    new_lines = new_lines,
  }

  local function accept()
    if vim.api.nvim_buf_is_valid(state.target_buf) then
      vim.api.nvim_buf_set_lines(state.target_buf, state.start_line - 1, state.end_line, false, state.new_lines)
      vim.notify("Qwen: change applied", vim.log.levels.INFO)
    end
    vim.cmd("tabclose")
    state = {}
  end

  local function reject()
    vim.cmd("tabclose")
    state = {}
  end

  bind(left_buf, accept, reject)
  bind(right_buf, accept, reject)
end

--- Show freshly generated content with no direct original counterpart (e.g.
--- generated tests) in its own tab. No accept/reject - just yank or :w it.
function M.show_new_file(code, ft)
  local buf = make_scratch_buf(vim.split(code, "\n", { plain = true }), ft)

  vim.cmd("tabnew")
  vim.api.nvim_win_set_buf(0, buf)

  vim.keymap.set("n", "q", function()
    vim.cmd("tabclose")
  end, { buffer = buf, desc = "Qwen: close" })

  vim.notify("Qwen: generated content opened in a new tab (q to close)", vim.log.levels.INFO)
end

return M
