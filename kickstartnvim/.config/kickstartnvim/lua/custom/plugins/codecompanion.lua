return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    strategies = {
      -- Change the default chat adapter
      chat = {
        adapter = 'anthropic',
      },
      inline = {
        adapter = 'anthropic',
      },
      cmd = {
        adapter = 'anthropic',
      },
    },
    opts = {
      -- Set debug logging
      log_level = 'DEBUG',
    },
    display = {
      chat = {
        show_settings = true,
      },
      action_palette = {
        provider = 'telescope',
      },
    },
  },
}
