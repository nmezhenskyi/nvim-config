local pack = require("config.pack")

pack.on_event("InsertEnter", function()
   -- Load nvim-cmp and LuaSnip before cmp sources so `after/plugin/` registers them
   pack.load({
      "nvim-cmp",
      "LuaSnip",
      "friendly-snippets",
      "cmp-nvim-lsp",
      "cmp-buffer",
      "cmp-path",
      "cmp-nvim-lua",
      "cmp_luasnip",
   })

   local cmp = require("cmp")
   local luasnip = require("luasnip")
   require("luasnip.loaders.from_vscode").lazy_load()

   local cmp_select = { behavior = cmp.SelectBehavior.Select }
   local source_labels = {
      nvim_lsp = "[LSP]",
      nvim_lua = "[Lua]",
      luasnip = "[Snip]",
      buffer = "[Buf]",
      path = "[Path]",
   }

   cmp.setup({
      snippet = {
         expand = function(args)
            luasnip.lsp_expand(args.body)
         end,
      },
      sources = {
         { name = "path" },
         { name = "nvim_lsp" },
         { name = "nvim_lua" },
         { name = "luasnip", keyword_length = 2 },
         { name = "buffer", keyword_length = 3 },
      },
      formatting = {
         fields = { "abbr", "kind", "menu" },
         format = function(entry, item)
            item.menu = source_labels[entry.source.name] or ("[" .. entry.source.name .. "]")
            -- Truncate by UTF-8 characters (not bytes) to avoid splitting multi-byte symbols
            if vim.fn.strchars(item.abbr) > 40 then
               item.abbr = vim.fn.strcharpart(item.abbr, 0, 39) .. "…"
            end
            return item
         end,
      },
      mapping = cmp.mapping.preset.insert({
         ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
         ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
         ["<CR>"] = cmp.mapping.confirm({ select = true }),
         ["<C-e>"] = cmp.mapping.abort(),
         ["<C-Space>"] = cmp.mapping.complete(),
      }),
   })

   -- cmp_nvim_lsp.setup() registers an InsertEnter autocmd to attach LSP sources;
   -- since we are already inside the first InsertEnter, invoke it once manually
   -- so LSP completions work without leaving and re-entering Insert mode.
   require("cmp_nvim_lsp")._on_insert_enter()
end)
