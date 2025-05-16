-- Use Tree-sitter for folding
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

-- Fallback to indent folding when Tree-sitter is not available
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    if not pcall(vim.treesitter.get_parser, 0) then
      vim.opt_local.foldmethod = 'indent'
    end
  end,
})

-- Performance: Disable folding for large files
vim.api.nvim_create_autocmd('BufReadPre', {
  callback = function()
    if vim.fn.getfsize(vim.fn.expand '%') > 1024 * 1024 then
      vim.opt_local.foldenable = false
    end
  end,
})

-- Start with all folds open
vim.opt.foldlevel = 99
