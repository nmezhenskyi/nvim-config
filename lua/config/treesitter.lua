-- Enable Neovim's built-in async Treesitter highlighting whenever a parser is
-- available on 'runtimepath' (bundled: c, lua, markdown, query, vim, vimdoc).
-- Languages without a parser automatically fall back to Vim syntax + LSP semantic tokens.
vim.api.nvim_create_autocmd("FileType", {
   group = vim.api.nvim_create_augroup("config_treesitter", { clear = true }),
   callback = function(ev)
      pcall(vim.treesitter.start, ev.buf)
   end,
})
