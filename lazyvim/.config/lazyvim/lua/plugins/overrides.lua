return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            auto_close = true,
            hidden = true,
            exclude = {
              ".git",
              ".DS_Store",
            },
          },
        },
      },
    },
  },
}
