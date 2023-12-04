-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
   -- Packer can manage itself
   use 'wbthomason/packer.nvim'

   use {
      'nvim-telescope/telescope.nvim', tag = '0.1.4',
      requires = { {'nvim-lua/plenary.nvim'} }
   } -- Ripgrep

   use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
   use('nvim-treesitter/playground')

   use('theprimeagen/harpoon')   -- Add files to quick switch list
   use('mbbill/undotree')        -- Undo tree
   use('tpope/vim-fugitive')     -- Git commands support

   use 'm4xshen/autoclose.nvim'  -- Set up autoclosing brackets

   -- LSP ---
   use {
      'VonHeikemen/lsp-zero.nvim',
      branch = 'v1.x',
      requires = {
         -- LSP Support
         {'neovim/nvim-lspconfig'},
         {'williamboman/mason.nvim'},
         {'williamboman/mason-lspconfig.nvim'},

         -- Autocompletion
         {'hrsh7th/nvim-cmp'},
         {'hrsh7th/cmp-buffer'},
         {'hrsh7th/cmp-path'},
         {'saadparwaiz1/cmp_luasnip'},
         {'hrsh7th/cmp-nvim-lsp'},
         {'hrsh7th/cmp-nvim-lua'},

         -- Snippets
         {'L3MON4D3/LuaSnip'},
         {'rafamadriz/friendly-snippets'},
      }
   }

   use 'Mofiqul/dracula.nvim'    -- Color theme
end)

