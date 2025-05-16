-- Buffer Keymaps
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>bn', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })

-- mini.files keymaps
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local buf_id = args.data.buf_id

    -- Map <esc><esc> to close explorer (same as 'q')
    vim.keymap.set('n', '<esc><esc>', MiniFiles.close, { buffer = buf_id })

    -- Map <cr> to do the same as go_in_plus (expand and close on file)
    vim.keymap.set('n', '<cr>', function()
      MiniFiles.go_in { close_on_file = true }
    end, { buffer = buf_id })
  end,
})
