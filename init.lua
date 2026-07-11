print("hello swordde!!!!!!:")

-- Enable true colors
vim.opt.termguicolors = true

-- Load configs
require("swordemon.packer")
require("swordemon.remap")
require("swordemon.set")

-- Colorscheme
vim.cmd.colorscheme("quiet")

-- Custom dark red theme tweaks
vim.api.nvim_set_hl(0, "Visual", {
    bg = "#3a0000",
})

vim.api.nvim_set_hl(0, "CursorLine", {
    bg = "#2a0000",
})

vim.api.nvim_set_hl(0, "Search", {
    bg = "#5a0000",
    fg = "#ffffff",
})

vim.api.nvim_set_hl(0, "IncSearch", {
    bg = "#ff0000",
    fg = "#000000",
})

-- Diagnostics
vim.diagnostic.config({
    virtual_text = {
        prefix = "●",
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    float = {
        border = "rounded",
        source = "always",
    },
})

-- Disable markdown syntax highlighting
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.cmd("syntax off")
    end,
})

-- Open terminal at bottom
vim.keymap.set("n", "<space>st", function()
    vim.cmd("vnew")
    vim.cmd("term")
    vim.cmd("wincmd J")
    vim.api.nvim_win_set_height(0, 5)
end, { desc = "Open terminal at bottom" })
