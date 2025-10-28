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

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local builtin = require 'telescope.builtin'
local themes = require 'telescope.themes'

vim.keymap.set('n', '<leader>sl', function()
  builtin.find_files {
    hidden = true,
    no_ignore = true,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not entry then
          return
        end
        local path = entry.path or entry.value
        path = vim.fn.fnamemodify(path, ':.') -- make path relative to the current cwd
        vim.api.nvim_put({ path }, '', true, true)
      end)
      return true
    end,
  }
end, { desc = '[S]earch fi[L]e path (insert)' })
