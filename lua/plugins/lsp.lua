local pack = require("config.pack")

-- Diagnostics: show inline virtual text on the current cursor line only,
-- truncated to 1 line / 80 chars so the screen stays uncluttered.
-- Gutter signs and underlines still mark all lines; <leader>vd shows the full float.
vim.diagnostic.config({
   severity_sort = true,
   virtual_text = {
      current_line = true, -- remove this line to show virtual text on all lines
      spacing = 2,
      source = "if_many",
      format = function(diagnostic)
         -- Show first line only and truncate by UTF-8 characters (not bytes)
         local msg = diagnostic.message:gsub("\n.*", "")
         if vim.fn.strchars(msg) > 80 then
            return vim.fn.strcharpart(msg, 0, 79) .. "…"
         end
         return msg
      end,
   },
   float = {
      border = "rounded",
      source = "if_many",
   },
})

-- Buffer-local LSP keymaps attached whenever any LSP client attaches
vim.api.nvim_create_autocmd("LspAttach", {
   group = vim.api.nvim_create_augroup("config_lsp_attach", { clear = true }),
   callback = function(ev)
      local opts = { buf = ev.buf, remap = false }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts)
      vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
   end,
})

-- Format on save for C/C++ (clangd) and Go (gopls)
local format_on_save_servers = {
   c = "clangd",
   cpp = "clangd",
   go = "gopls",
}

vim.api.nvim_create_autocmd("BufWritePre", {
   group = vim.api.nvim_create_augroup("config_lsp_format", { clear = true }),
   callback = function(ev)
      local server = format_on_save_servers[vim.bo[ev.buf].filetype]
      if not server then
         return
      end

      local clients = vim.lsp.get_clients({ bufnr = ev.buf, name = server })
      if #clients == 0 then
         return
      end

      vim.lsp.buf.format({
         bufnr = ev.buf,
         async = false,
         timeout_ms = 10000,
         filter = function(client)
            return client.name == server
         end,
      })
   end,
})

-- Lazy-load Mason + nvim-lspconfig on first file open or LSP/Mason command.
-- Note: :LspInstall and :LspUninstall are provided natively by mason-lspconfig.
pack.defer({
   event = { "BufReadPre", "BufNewFile" },
   cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog", "LspInstall", "LspUninstall", "LspUpdate" },
   load = function()
      -- Load cmp-nvim-lsp without sourcing its after/plugin yet (nvim-cmp loads on InsertEnter)
      pack.load("cmp-nvim-lsp", { after_plugin = false })
      pack.load({ "nvim-lspconfig", "mason.nvim", "mason-lspconfig.nvim" })

      -- Pass nvim-cmp capabilities to all LSP servers
      vim.lsp.config("*", {
         capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      -- Neovim-aware configuration for lua_ls
      vim.lsp.config("lua_ls", {
         settings = {
            Lua = {
               runtime = { version = "LuaJIT" },
               diagnostics = { globals = { "vim" } },
               workspace = {
                  checkThirdParty = false,
                  library = vim.api.nvim_get_runtime_file("", true),
               },
               telemetry = { enable = false },
            },
         },
      })

      require("mason").setup({
         ui = { border = "rounded" },
      })

      -- Install servers on demand (ensure_installed = {}); anything installed via
      -- Mason is automatically enabled using native `vim.lsp.enable()`.
      require("mason-lspconfig").setup({
         ensure_installed = {},
         automatic_enable = true,
      })

      -- Also enable common servers if already installed on the system PATH
      local system_servers = {
         clangd = "clangd",
         gopls = "gopls",
         ts_ls = "typescript-language-server",
         lua_ls = "lua-language-server",
      }
      for server, bin in pairs(system_servers) do
         if vim.fn.executable(bin) == 1 then
            vim.lsp.enable(server)
         end
      end

      -- Resolve an lspconfig server name (e.g. "ts_ls", "lua_ls") to its Mason package name
      local function to_mason_name(name)
         local ok, mappings = pcall(require, "mason-lspconfig.mappings")
         if ok and mappings.get_mason_map then
            local lsp_to_pkg = mappings.get_mason_map().lspconfig_to_package
            if lsp_to_pkg and lsp_to_pkg[name] then
               return lsp_to_pkg[name]
            end
         end
         return name
      end

      -- :LspUpdate [server...] — refresh Mason registry and update installed LSPs
      vim.api.nvim_create_user_command("LspUpdate", function(args)
         local registry = require("mason-registry")
         vim.notify("Refreshing Mason registry...", vim.log.levels.INFO)

         registry.refresh(vim.schedule_wrap(function()
            local targets = {}
            if #args.fargs > 0 then
               for _, arg in ipairs(args.fargs) do
                  local pkg_name = to_mason_name(arg)
                  local ok, pkg = pcall(registry.get_package, pkg_name)
                  if ok then
                     table.insert(targets, pkg)
                  else
                     vim.notify("Unknown Mason package: " .. arg, vim.log.levels.WARN)
                  end
               end
            else
               targets = registry.get_installed_packages()
            end

            if #targets == 0 then
               vim.notify("No installed Mason LSP packages to update.", vim.log.levels.INFO)
               return
            end

            local updated = 0
            for _, pkg in ipairs(targets) do
               local installed = pkg:get_installed_version()
               -- pcall guards against malformed package URLs; skip if already installing
               local ok_latest, latest = pcall(pkg.get_latest_version, pkg)
               if ok_latest and installed ~= latest and not pkg:is_installing() then
                  updated = updated + 1
                  vim.notify(
                     string.format("Updating %s (%s -> %s)...", pkg.name, installed or "?", latest or "?"),
                     vim.log.levels.INFO
                  )
                  -- Use install callback (not :once("closed")) to distinguish success vs failure
                  pkg:install(nil, vim.schedule_wrap(function(success)
                     if success then
                        vim.notify("Updated " .. pkg.name, vim.log.levels.INFO)
                     else
                        vim.notify("Failed to update " .. pkg.name, vim.log.levels.ERROR)
                     end
                  end))
               end
            end

            if updated == 0 then
               vim.notify("All installed Mason LSP packages are already up to date.", vim.log.levels.INFO)
            end
         end))
      end, {
         nargs = "*",
         desc = "Update installed LSP servers via Mason",
         complete = function(arg_lead)
            local ok, mlsp = pcall(require, "mason-lspconfig")
            local servers = ok and mlsp.get_installed_servers and mlsp.get_installed_servers() or {}
            return vim.tbl_filter(function(s)
               return vim.startswith(s, arg_lead)
            end, servers)
         end,
      })
   end,
})
