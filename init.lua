print("hello swordde!!!!!!:")
-- Load all Lua configs from swordemon folde  -- plugins fi  -- then Tree-sitter config


require("swordemon.packer")

require("swordemon.remap")

vim.opt.termguicolors =true

require("swordemon.set")
-- theme setter for nvim ,DARk red
vim.api.nvim_set_hl(0, "Visual", { bg = "#3a0000" })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a0000" })
vim.api.nvim_set_hl(0, "Search", { bg = "#5a0000", fg = "#ffffff" })
vim.api.nvim_set_hl(0, "IncSearch", { bg = "#ff0000", fg = "#000000" })

 vim.diagnostic.config({
  virtual_text = {
    prefix = "●", -- or "▎"
  },
  signs = true,
  underline = true,
  float = {
    border = "rounded",
    source = "always",
  },
  update_in_insert = false,

})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.cmd("syntax off")
  end,
})



vim.keymap.set("n","<space>st" , function()
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0,5)
end)
