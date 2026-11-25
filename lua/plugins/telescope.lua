local pack = require("nikita.pack")

local load_telescope = pack.defer({
   cmd = { "Telescope" },
   load = function()
      pack.load({ "plenary.nvim", "telescope.nvim" })
   end,
})

local function builtin()
   load_telescope()
   return require("telescope.builtin")
end

-- Requires ripgrep to be installed.
vim.keymap.set("n", "<leader>pf", function() builtin().find_files() end, { desc = "Telescope find files" })
vim.keymap.set("n", "<C-p>", function() builtin().git_files() end, { desc = "Telescope git files" })
vim.keymap.set("n", "<leader>pg", function() builtin().git_status() end, { desc = "Telescope git status" })
vim.keymap.set("n", "<leader>ps", function()
   builtin().grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Telescope grep string" })
