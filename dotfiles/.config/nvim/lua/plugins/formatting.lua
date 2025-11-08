-- ~/.config/nvim/lua/plugins/formatting.lua
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        svelte = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        dart = { "dart_format" },
      },
    },
  },
}
