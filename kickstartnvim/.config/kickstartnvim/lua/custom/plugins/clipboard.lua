return {
  'gbprod/yanky.nvim',
  dependencies = {
    { 'kkharji/sqlite.lua' },
  },
  opts = {
    ring = { history_length = 20, storage = 'sqlite' },
    highlight = {
      timer = 250,
    },
  },
  keys = {
    { '<leader>p', '<cmd>YankyRingHistory<cr>', mode = { 'n', 'x' }, desc = 'Open Yank History' },
    { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text' },
    { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put yanked text after cursor' },
    { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' }, desc = 'Put yanked text before cursor' },
  },
}
