return {
   -- Autoclosing brackets:
   "m4xshen/autoclose.nvim",
   lazy = false,
   priority = 100,
   config = function()
      require('autoclose').setup()
   end,
}

