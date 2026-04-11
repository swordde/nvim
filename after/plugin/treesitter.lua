require'nvim-treesitter'.setup {
  ensure_installed = { 
    "help", "go", "lua", "python", "cpp", "c", "vim", "vimdoc", "query", 
    "markdown", "markdown_inline", "bash"
  },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

-- Force Treesitter to attach to all buffers (not just Telescope previews)
vim.api.nvim_create_autocmd({'BufReadPost','FileReadPost'}, {
  callback = function() vim.treesitter.start() end
})
