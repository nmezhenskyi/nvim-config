local M = {}

local loaded = {}
local loaded_after = {}

local function gh(repo)
   return "https://github.com/" .. repo
end

--- Source a plugin's `after/plugin/` scripts when loaded after startup.
--- `:packadd` adds `after/` to 'runtimepath' but does not source `after/plugin/`
--- once initialization has finished (v:vim_did_init == 1).
---@param name string
function M.source_after(name)
   if loaded_after[name] or vim.v.vim_did_init ~= 1 then
      return
   end
   loaded_after[name] = true

   local info = vim.pack.get({ name }, { info = false })[1]
   if not info or not info.path then
      return
   end

   local after_dir = info.path .. "/after/plugin"
   if not vim.uv.fs_stat(after_dir) then
      return
   end

   local files = vim.fn.globpath(after_dir, "**/*", false, true)
   for _, file in ipairs(files) do
      if file:match("%.lua$") or file:match("%.vim$") then
         vim.cmd.source(file)
      end
   end
end

--- Load one or more optional plugins installed via `vim.pack`.
---@param names string|string[]
---@param opts? { after_plugin?: boolean }
function M.load(names, opts)
   opts = opts or {}
   if type(names) == "string" then
      names = { names }
   end

   for _, name in ipairs(names) do
      if not loaded[name] then
         loaded[name] = true
         vim.cmd.packadd(name)
      end
      if opts.after_plugin ~= false then
         M.source_after(name)
      end
   end
end

--- Run a callback once on any of the given autocmd events.
---@param events string|string[]
---@param callback fun(ev: table)
function M.on_event(events, callback)
   vim.api.nvim_create_autocmd(events, {
      once = true,
      callback = callback,
   })
end

--- Defer a loader behind autocmd events and/or stub user commands.
--- Stub commands are always removed cleanly before `load` runs so they never
--- collide with real commands defined by the plugin.
---@param opts { event?: string|string[], cmd?: string[], load: fun() }
---@return fun() trigger
function M.defer(opts)
   local done = false
   local cmds = opts.cmd or {}

   local function clear_stubs()
      for _, c in ipairs(cmds) do
         pcall(vim.api.nvim_del_user_command, c)
      end
   end

   local function trigger()
      if done then
         return
      end
      done = true
      clear_stubs()
      opts.load()
   end

   if opts.event then
      vim.api.nvim_create_autocmd(opts.event, {
         once = true,
         callback = trigger,
      })
   end

   for _, cmd in ipairs(cmds) do
      vim.api.nvim_create_user_command(cmd, function(args)
         trigger()

         local range = ""
         if args.range == 1 then
            range = tostring(args.line1)
         elseif args.range == 2 then
            range = string.format("%d,%d", args.line1, args.line2)
         end

         local bang = args.bang and "!" or ""
         local mods = args.mods ~= "" and (args.mods .. " ") or ""
         local tail = args.args ~= "" and (" " .. args.args) or ""
         vim.cmd(mods .. range .. cmd .. bang .. tail)
      end, {
         nargs = "*",
         bang = true,
         range = true,
         complete = function(_, line)
            trigger()
            return vim.fn.getcompletion(line, "cmdline")
         end,
      })
   end

   return trigger
end

-- Register all plugins in a single vim.pack.add() call (parallel install, one lockfile).
-- Only plugins marked `eager = true` are loaded at startup; the rest load on demand.
vim.pack.add({
   { src = gh("Mofiqul/dracula.nvim"), data = { eager = true } },

   -- Lazy-loaded plugins
   gh("nvim-lua/plenary.nvim"),
   gh("m4xshen/autoclose.nvim"),
   { src = gh("ThePrimeagen/harpoon"), version = "harpoon2" },
   gh("nvim-telescope/telescope.nvim"),
   gh("tpope/vim-fugitive"),

   -- LSP & on-demand server management
   gh("neovim/nvim-lspconfig"),
   gh("mason-org/mason.nvim"),
   gh("mason-org/mason-lspconfig.nvim"),

   -- Autocompletion & snippets
   gh("hrsh7th/nvim-cmp"),
   gh("hrsh7th/cmp-nvim-lsp"),
   gh("hrsh7th/cmp-buffer"),
   gh("hrsh7th/cmp-path"),
   gh("hrsh7th/cmp-nvim-lua"),
   gh("saadparwaiz1/cmp_luasnip"),
   gh("L3MON4D3/LuaSnip"),
   gh("rafamadriz/friendly-snippets"),
}, {
   load = function(plug_data)
      if plug_data.spec.data and plug_data.spec.data.eager then
         local name = plug_data.spec.name
         loaded[name] = true
         vim.cmd.packadd({ name, bang = vim.v.vim_did_init == 0 })
      end
   end,
})

-- Convenience commands for managing plugins via built-in vim.pack
vim.api.nvim_create_user_command("PackUpdate", function()
   vim.pack.update()
end, { desc = "Update plugins via vim.pack" })

vim.api.nvim_create_user_command("PackClean", function()
   local inactive = vim.iter(vim.pack.get())
      :filter(function(p) return not p.active end)
      :map(function(p) return p.spec.name end)
      :totable()

   if #inactive == 0 then
      vim.notify("No unused plugins to clean.", vim.log.levels.INFO)
      return
   end

   vim.pack.del(inactive)
   vim.notify("Removed unused plugins: " .. table.concat(inactive, ", "), vim.log.levels.INFO)
end, { desc = "Remove inactive vim.pack plugins from disk" })

-- Expose helper module before loading plugin configs
package.loaded["config.pack"] = M

require("plugins.colorscheme")
require("plugins.autoclose")
require("plugins.harpoon")
require("plugins.telescope")
require("plugins.vim-fugitive")
require("plugins.lsp")
require("plugins.cmp")

return M
