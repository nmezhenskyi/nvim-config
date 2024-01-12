return {
   {
      "VonHeikemen/lsp-zero.nvim",
      branch = "v3.x",
      lazy = true,
      config = false,
      init = function()
         -- Disable automatic setup, do it manually later:
         vim.g.lsp_zero_extend_cmp = 0
         vim.g.lsp_zero_extend_lspconfig = 0
      end
   },

   -- Install & manage LSP servers:
   {
      "williamboman/mason.nvim",
      lazy = false,
      config = true,
   }, -- needs mason-lspconfig to integrate with lspconfig.
   
   -- Autocompletion plugins:
   {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter", -- load cmp on InsertEnter
      dependencies = {
         {
            "L3MON4D3/LuaSnip",
            dependencies = { "rafamadriz/friendly-snippets" },
         },
      },
      config = function()
         -- Autocompletion settings:
         local lsp_zero = require("lsp-zero")
         lsp_zero.extend_cmp()

         local cmp = require("cmp")
         local cmp_select = {behavior = cmp.SelectBehavior.Select}

         cmp.setup({
            sources = {
               {name = "path"},
               {name = "nvim_lsp"},
               {name = "nvim_lua"},
               {name = "luasnip", keyword_length = 2},
               {name = "buffer", keyword_length = 3},
            },
            formatting = lsp_zero.cmp_format(),
            mapping = cmp.mapping.preset.insert({
               ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
               ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
               ["<CR>"] = cmp.mapping.confirm({ select = true }),
               ["<C-e>"] = cmp.mapping.abort(),
               ["<C-Space>"] = cmp.mapping.complete(),
            })
         })
      end
   },

   -- LSP:
   {
      "neovim/nvim-lspconfig",
      cmd = {"LspInfo", "LspInstall", "LspStart"},
      event = { "BufReadPre", "BufNewFile" },
      dependencies = {
         { "hrsh7th/cmp-nvim-lsp" },
         { "hrsh7th/cmp-buffer" },
         { "hrsh7th/cmp-path" },
         { "saadparwaiz1/cmp_luasnip" },
         { "hrsh7th/cmp-nvim-lua" },
         { "williamboman/mason-lspconfig.nvim" },
      },
      config = function()
         local lsp_zero = require("lsp-zero")
         lsp_zero.extend_lspconfig()

         lsp_zero.on_attach(function(client, bufnr)
            local opts = {buffer = bufnr, remap = false}
            vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
            vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, opts)
            vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
            vim.keymap.set("n", "<leader>ws", function() vim.lsp.buf.workspace_symbol() end, opts)
            vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
            -- vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
            -- vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
            vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
            vim.keymap.set("n", "<leader>gr", function() vim.lsp.buf.references() end, opts)
            vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
            vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
         end)

         lsp_zero.format_on_save({
            format_opts = {
               async = false,
               timeout_ms = 10000,
            },
            servers = {
               ["clangd"] = { "c", "cpp" }, 
            },
         })

         require("mason-lspconfig").setup({
            ensure_installed = { "clangd", "gopls", "tsserver" },
            handlers = {
               lsp_zero.default_setup,
               lua_ls = function()
                  local lua_opts = lsp_zero.nvim_lua_ls()
                  require('lspconfig').lua_ls.setup(lua_opts)
               end,
            }
         })
      end
   }
}

