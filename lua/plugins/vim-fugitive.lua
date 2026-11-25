local pack = require("config.pack")

local load_fugitive = pack.defer({
   cmd = { "Git", "G" },
   load = function()
      pack.load("vim-fugitive")
   end,
})

vim.keymap.set("n", "<leader>gs", function()
   load_fugitive()
   vim.cmd.Git()
end, { desc = "Fugitive Git status" })
