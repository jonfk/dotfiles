local default_model = 'z-ai/glm-4.5'
local available_models = {
  'z-ai/glm-4.5',
  'deepseek/deepseek-chat-v3.1',
  'google/gemini-2.5-flash',
  'google/gemini-2.5-pro',
  'openai/gpt-5',
  'anthropic/claude-sonnet-4',
}
local current_model = default_model

local function select_model()
  vim.ui.select(available_models, {
    prompt = 'Select  Model:',
  }, function(choice)
    if choice then
      current_model = choice
      vim.notify('Selected model: ' .. current_model)
    end
  end)
end

vim.keymap.set('n', '<leader>cs', select_model, { desc = 'Select OpenRouter Model' })
vim.keymap.set({ 'n', 'v' }, '<leader>ck', '<cmd>CodeCompanionActions<cr>', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, '<leader>cc', '<cmd>CodeCompanionChat Toggle<cr>', { noremap = true, silent = true })
vim.keymap.set('v', '<leader>ca', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true })

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
        adapter = 'openrouter',
      },
      inline = {
        adapter = 'openrouter',
      },
      cmd = {
        adapter = 'openrouter',
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
    adapters = {
      http = {
        openrouter = function()
          return require('codecompanion.adapters').extend('openai_compatible', {
            env = {
              url = 'https://openrouter.ai/api',
              api_key = 'CODE_COMP_OPRO_API_KEY',
              chat_url = '/v1/chat/completions',
            },
            schema = {
              model = {
                default = current_model,
              },
            },
          })
        end,
      },
    },
  },
}
