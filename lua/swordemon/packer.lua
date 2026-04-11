vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use 'wbthomason/packer.nvim'
		-- Treesitter for advanced syntax highlighting
	use{
		'nvim-treesitter/nvim-treesitter',
		lazy = false,
		build = ':TSUpdate'
	}

	-- Telescope
use {
    'nvim-telescope/telescope.nvim',
    tag = '*',  -- equivalent of version='*'
    requires = {
        'nvim-lua/plenary.nvim',
        { 
            'nvim-telescope/telescope-fzf-native.nvim', 
            run = 'make' 
        },
    },
}
	

	-- Rose-pine theme
	use {
		'rose-pine/neovim',
		as = "rose-pine",
		config = function()
			vim.cmd("colorscheme rose-pine")
		end
	}
  -- supermaven

   use({
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<Tab>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-j>",
        },
        ignore_filetypes = { "env", "log", "bigfile" },
        color = {
          suggestion_color = "#808080",
        },
      })
    end,
  })




	-- Add these inside your packer.startup(function(use) ... end)
	use { "L3MON4D3/LuaSnip" } 
	use { "hrsh7th/cmp-buffer" }
	use { "hrsh7th/cmp-path" }
	use { "saadparwaiz1/cmp_luasnip" }

	use ("theprimeagen/harpoon")

	use ("mbbill/undotree")
	use ("tpope/vim-fugitive")

	use {
		"neovim/nvim-lspconfig"
	}

	use {
		"williamboman/mason.nvim"
	}

	use {
		"williamboman/mason-lspconfig.nvim"
	}

	use {
		"hrsh7th/nvim-cmp"
	}

	use {
		"hrsh7th/cmp-nvim-lsp"
	}

	use "nvim-lua/plenary.nvim"
	
	use "christoomey/vim-tmux-navigator"
	use{
		"lima1909/resty.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
	}end)
