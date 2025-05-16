vim.o.guifont = 'Hack Nerd Font:h14'
vim.g.neovide_position_animation_length = 0.15
vim.g.neovide_scroll_animation_length = 0.05
vim.g.neovide_input_macos_option_key_is_meta = 'only_left'

vim.keymap.set('n', '<D-v>', '"+P', { desc = 'Paste from system clipboard in normal mode' })
vim.keymap.set('v', '<D-v>', '"+P', { desc = 'Paste from system clipboard in visual mode' })
vim.keymap.set('c', '<D-v>', '<C-R>+', { desc = 'Paste from system clipboard in command mode' })
vim.keymap.set('i', '<D-v>', '<ESC>l"+Pli', { desc = 'Paste from system clipboard in insert mode' })

-- Allow clipboard copy paste in neovim
vim.api.nvim_set_keymap('', '<D-v>', '+p<CR>', {
  noremap = true,
  silent = true,
  desc = 'Paste from clipboard register and execute in all modes',
})

vim.api.nvim_set_keymap('!', '<D-v>', '<C-R>+', {
  noremap = true,
  silent = true,
  desc = 'Paste from system clipboard in insert and command-line modes',
})

vim.api.nvim_set_keymap('t', '<D-v>', '<cmd>lua local clipboard_content = vim.fn.getreg("+"); vim.api.nvim_put({ clipboard_content }, "l", true, true)<CR>', {
  noremap = true,
  silent = true,
  desc = 'Paste from system clipboard in terminal mode using Lua function',
})

vim.api.nvim_set_keymap('v', '<D-v>', '<C-R>+', {
  noremap = true,
  silent = true,
  desc = 'Paste from system clipboard in visual mode',
})
