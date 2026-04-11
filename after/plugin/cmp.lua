local cmp = require("cmp")

cmp.setup({
  mapping = {
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-R>"] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = "nvim_lsp" },
  },
})

