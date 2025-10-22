return {
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'VeryLazy', -- You can make it lazy-loaded via VeryLazy, but comment out if anything doesn’t work
    version = false,
    init = function()
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
    end,
    opts = {
      provider_selector = function(bufnr, filetype, buftype)
        return { 'treesitter', 'indent' }
      end,
    },
  },
}
