function Cp(color)
  color = color or "rose-pine"
  vim.cmd.colorscheme(color)

  -- Enable true colors
  vim.opt.termguicolors = true

  -- Transparent background
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

  -- Groups to remove background
  local groups = {
    "Normal",
    "NormalNC",
    "VertSplit",
    "StatusLine",
    "StatusLineNC",
    "NonText",
    "LineNr",
    "SignColumn",
  }

  for _, group in ipairs(groups) do
    vim.cmd("highlight " .. group .. " guibg=NONE ctermbg=NONE")
  end

  -- Red accent adjustments
  vim.api.nvim_set_hl(0, "Title", { fg = "#eb6f92", bold = true })
  vim.api.nvim_set_hl(0, "Statement", { fg = "#eb6f92" })
  vim.api.nvim_set_hl(0, "Identifier", { fg = "#f7768e" })
  vim.api.nvim_set_hl(0, "Function", { fg = "#ff6a6a" })
  vim.api.nvim_set_hl(0, "Special", { fg = "#eb6f92" })

  -- Visual selection
  vim.api.nvim_set_hl(0, "Visual", { bg = "#3a1f2b" })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a1a23" })

  -- Search colors
  vim.api.nvim_set_hl(0, "Search", { bg = "#5a2a3a", fg = "#ffffff" })
  vim.api.nvim_set_hl(0, "IncSearch", { bg = "#eb6f92", fg = "#000000" })

  -- netrw file coloring
  vim.api.nvim_set_hl(0, "netrwPlain", { fg = "#e0def4" })        -- files
  vim.api.nvim_set_hl(0, "netrwDir", { fg = "#eb6f92", bold = true }) -- folders
  vim.api.nvim_set_hl(0, "netrwExe", { fg = "#f7768e" })          -- executables
  vim.api.nvim_set_hl(0, "netrwLink", { fg = "#c4a7e7" })         -- symlinks
  vim.api.nvim_set_hl(0, "netrwClassify", { fg = "#eb6f92" })
end

Cp()
