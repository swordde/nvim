print("hello swordde!!!!!!:")

-- Enable true colors
vim.opt.termguicolors = true

-- Load configs
require("swordemon.packer")
require("swordemon.remap")
require("swordemon.set")

-- Colorscheme
vim.cmd.colorscheme("quiet")
-- Softer colors for eye comfort
-- Softer code colors for eye comfort
local groups = {
    "Normal",
    "NormalNC",
    "Identifier",
    "Statement",
    "Function",
    "Keyword",
    "Type",
    "Constant",
    "Operator",
    "@variable",
    "@function",
    "@keyword",
}

for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, {
        fg = "#A0A0A0",
    })
end
vim.api.nvim_set_hl(0, "Normal", {
    fg = "#FFB3B3",
    bg = "#080808",
})

vim.api.nvim_set_hl(0, "NormalNC", {
    fg = "#FFB3B3",
    bg = "#080808",
})

-- Comments: dim grey
vim.api.nvim_set_hl(0, "Comment", {
    fg = "#666666",
})

-- Strings: muted warm grey
vim.api.nvim_set_hl(0, "String", {
    fg = "#B0A090",
})

-- Red cursor
vim.api.nvim_set_hl(0, "Cursor", {
    fg = "#000000",
    bg = "#808080",
})
--Stutus line
vim.api.nvim_set_hl(0, "StatusLine", {
    fg = "#808080",
    bg = "#111111",
})
-- Error message colors
vim.api.nvim_set_hl(0, "ErrorMsg", {
    fg = "#FFB3B3",
    bg = "#808080",
    bold = true,
})
vim.opt.guicursor = {
    "n-v-c:block-Cursor",
    "i-ci:ver25-Cursor",
    "r-cr:hor20-Cursor",
}

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

-- Disable Markdown syntax highlighting
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
    vim.cmd("wincmd L")
    vim.api.nvim_win_set_height(0, 30)
    vim.api.nvim_win_set_width(0, 49)
end, {
    desc = "Open terminal at bottom",
})

-- Qwen chat command
vim.api.nvim_create_user_command("QwenChat", function()
    require("qwen").chat()
end, {})

-- Exit terminal mode with Escape
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", {
    noremap = true,
    silent = true,
})
