return {
  "mason-org/mason.nvim",
  cmd = "Mason",
  build = ":MasonUpdate",
  opts = {
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
    max_concurrent_installers = 4,
    ensure_installed = {
      -- lua tools
      "stylua",
      "lua-language-server",
      "shellcheck",
      "shfmt",
      "flake8",
      "hadolint",
      -- go tools
      "gofumpt",
      "goimports",
      "gopls",
      -- python tools
      "pylint",
      "ruff",
      -- javascript/typescript tools
      "typescript-language-server",
      "eslint-lsp",
      "deno",
      -- json tools
      "jsonnet-language-server",
      -- markdown tools
      "marksman",
      -- sql tools
      "sqlfluff",
      "bash-language-server",
      "dart-debug-adapter",
    },
  },
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
  },
}
