return {
   -- Git commands support:
   "tpope/vim-fugitive",
   config = function()
      vim.keymap.set('n', '<leader>gs', vim.cmd.Git)
   end,
}

