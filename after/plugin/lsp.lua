-----------------------------------------------------------
-- Mason
-----------------------------------------------------------
require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    "clangd",
    "pyright",
    "lua_ls",
    "gopls",
  },
})

-----------------------------------------------------------
-- Capabilities (nvim-cmp)
-----------------------------------------------------------
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-----------------------------------------------------------
-- on_attach (keymaps)
-----------------------------------------------------------
local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr }

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
end

-----------------------------------------------------------
-- LSP Configs (NEW Neovim 0.11 API)
-----------------------------------------------------------

-- C / C++
vim.lsp.config("clangd", {
  capabilities = capabilities,
  on_attach = on_attach,
})
vim.lsp.enable("clangd")

-- Python
vim.lsp.config("pyright", {
  capabilities = capabilities,
  on_attach = on_attach,
})
vim.lsp.enable("pyright")

-- Lua
vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})
vim.lsp.enable("lua_ls")

-- Go
vim.lsp.config("gopls", {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
      gofumpt = true,
    },
  },
})
vim.lsp.enable("gopls")

-----------------------------------------------------------
-- Go: Auto-imports + Format on Save
-----------------------------------------------------------
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    -- ensure gopls is attached
    if not vim.lsp.get_active_clients({ name = "gopls" })[1] then
      return
    end

    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }

    local result = vim.lsp.buf_request_sync(
      0,
      "textDocument/codeAction",
      params,
      1000
    )

    for cid, res in pairs(result or {}) do
      for _, action in pairs(res.result or {}) do
        if action.edit then
          local enc =
            (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(action.edit, enc)
        end
      end
    end

    -- gofmt / gofumpt
    vim.lsp.buf.format({ async = false })
  end,
})

-----------------------------------------------------------
-- Diagnostics UI (recommended)
-----------------------------------------------------------
vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
  },
  signs = true,
  underline = true,
  float = {
    border = "rounded",
    source = "always",
  },
  update_in_insert = false,
})

-- keymap to show error under cursor
vim.keymap.set("n", "<leader>e", function()
  vim.diagnostic.open_float(nil, { focus = false })
end, { desc = "Show diagnostics" })
