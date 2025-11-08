return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- add tsx and treesitter
    vim.list_extend(opts.ensure_installed, {
      "tsx",
      "typescript",
      "go",
      "dart",
      "lua",
      "python",
      "bash",
      "html",
      "javascript",
      "json",
      "markdown",
      "markdown_inline",
      "yaml",
    })
  end,
}
