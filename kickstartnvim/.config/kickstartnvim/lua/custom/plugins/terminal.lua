return {
  {
    'akinsho/toggleterm.nvim',
    version = false, -- Use latest main because the tagged version is old. Recheck and update if it's been updated
    opts = {
      direction = 'float',
      open_mapping = [[<C-\>]],
      insert_mappings = true,
      terminal_mappings = true,
    },
    config = function(_, opts)
      local toggleterm = require 'toggleterm'
      toggleterm.setup(opts)

      vim.keymap.set('n', '<leader>tt', '<cmd>ToggleTerm<cr>', { desc = 'ToggleTerm Terminal' })

      vim.keymap.set('n', '<leader>tn', function()
        -- Get the directory of the current buffer's file
        local target_dir = vim.fn.expand '%:p:h'
        local nvim_cwd = vim.fn.getcwd()

        -- Check if the directory is valid, otherwise fallback to neovim's current working directory
        if vim.fn.isdirectory(target_dir) == 0 then
          target_dir = nvim_cwd
        end

        -- Calculate the relative path for the name
        local term_name
        local relative_path = vim.fn.fnamemodify(target_dir, ':~:.') -- Use :~ to represent home dir if path contains home dir
        if relative_path == '.' or relative_path == '' then
          -- If the target is the cwd, use the directory's basename as the name
          term_name = vim.fn.fnamemodify(target_dir, ':t') -- :t gets the tail/basename
        else
          term_name = relative_path
        end

        -- Ensure the name is not empty, fallback to basename if needed
        if term_name == '' then
          term_name = vim.fn.fnamemodify(target_dir, ':t')
        end

        -- Escape the directory path and the name for the command
        local escaped_dir = vim.fn.fnameescape(target_dir)
        local escaped_name = vim.fn.fnameescape(term_name)

        -- Open a new terminal with the specified directory and name
        vim.cmd('TermNew dir=' .. escaped_dir .. ' name=' .. escaped_name)
      end, { desc = 'ToggleTerm: New terminal (using buffer cwd)' })

      vim.keymap.set('n', '<leader>tr', function()
        local nvim_cwd = vim.fn.getcwd()
        local found_id = nil

        -- Get the map of active terminals { id = terminal_object }
        local ok, terms_map = pcall(toggleterm.get_terminals)
        if not ok or not terms_map then
          vim.notify('Could not retrieve ToggleTerm terminals.', vim.log.levels.WARN)
          terms_map = {} -- Ensure terms_map is iterable
        end

        for id, term in pairs(terms_map) do
          -- Check if the terminal object and its options exist, and if the initial directory matches
          if term and term.opts and term.opts.dir == nvim_cwd then
            found_id = id
            break
          end
        end

        if found_id then
          -- If a matching terminal exists, toggle it using its ID
          vim.cmd(found_id .. 'ToggleTerm')
        else
          -- If no matching terminal exists, create a new one
          local escaped_dir = vim.fn.fnameescape(nvim_cwd)
          vim.cmd('TermNew dir=' .. escaped_dir)
        end
      end, { desc = 'ToggleTerm: Toggle/New terminal (nvim cwd)' })

      vim.keymap.set('n', '<leader>ts', '<cmd>TermSelect<cr>', { desc = 'Terminal Select' })
    end,
  },
  {
    'ryanmsnyder/toggleterm-manager.nvim',
    dependencies = {
      'akinsho/nvim-toggleterm.lua',
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim', -- only needed because it's a dependency of telescope
    },
    config = true,
  },
}
