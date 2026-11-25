local pack = require("config.pack")

local harpoon
local function get_harpoon()
   if not harpoon then
      pack.load({ "plenary.nvim", "harpoon" })
      harpoon = require("harpoon")
      harpoon:setup()
   end
   return harpoon
end

vim.keymap.set("n", "<leader>pc", function() get_harpoon():list():add() end, { desc = "Harpoon add file" })
vim.keymap.set("n", "<C-e>", function()
   local h = get_harpoon()
   h.ui:toggle_quick_menu(h:list())
end, { desc = "Harpoon quick menu" })

vim.keymap.set("n", "<C-h>", function() get_harpoon():list():select(1) end, { desc = "Harpoon select 1" })
vim.keymap.set("n", "<C-t>", function() get_harpoon():list():select(2) end, { desc = "Harpoon select 2" })
vim.keymap.set("n", "<C-n>", function() get_harpoon():list():select(3) end, { desc = "Harpoon select 3" })
vim.keymap.set("n", "<C-s>", function() get_harpoon():list():select(4) end, { desc = "Harpoon select 4" })

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<C-S-P>", function() get_harpoon():list():prev() end, { desc = "Harpoon prev" })
vim.keymap.set("n", "<C-S-N>", function() get_harpoon():list():next() end, { desc = "Harpoon next" })
