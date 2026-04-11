return {
  "supermaven-inc/supermaven-nvim",
  config = function()
    require("supermaven-nvim").setup({
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
      },
      ignore_filetypes = { "env", "log", "bigfile" }, -- Don't leak secrets or lag on logs
      color = {
        suggestion_color = "#808080", -- Subtle grey for ghost text
      },
      disable_inline_completion = false, -- Keep ghost text on
    })
  end,
}
