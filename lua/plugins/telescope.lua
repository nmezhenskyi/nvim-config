return {
   -- Requires ripgrep to b installed.
   "nvim-telescope/telescope.nvim",
   tag = "0.1.5",
   dependencies = { "nvim-lua/plenary.nvim" },
   config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
      vim.keymap.set("n", "<C-p>", builtin.git_files, {})
      vim.keymap.set("n", "<leader>pg", builtin.git_status, {})
      vim.keymap.set("n", "<leader>ps", function()
         builtin.grep_string({ search = vim.fn.input("Grep > ") });
      end)
   end,
}

